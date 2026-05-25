import XCTest
@testable import AcmeBank

/// Tests for `OktaAuthService`.
///
/// All tests use a `FakeDirectAuthFlow` stub so we never touch the
/// network or the real `OktaDirectAuth` SDK. The `KeychainStore` is
/// scoped to a unique `service` per test to keep simulator keychain
/// state from bleeding between cases.
final class OktaAuthServiceTests: XCTestCase {

    // MARK: - Test fakes

    /// Stub `DirectAuthFlowPerforming`. Returns the configured token
    /// result or throws the configured error. Also captures the
    /// (username, password) it was called with so tests can assert
    /// the values flowed through unchanged.
    private final class FakeDirectAuthFlow: DirectAuthFlowPerforming {
        var result: Result<OktaTokenResult, Error>
        private(set) var capturedUsername: String?
        private(set) var capturedPassword: String?

        init(result: Result<OktaTokenResult, Error>) {
            self.result = result
        }

        func authenticate(username: String, password: String) async throws -> OktaTokenResult {
            capturedUsername = username
            capturedPassword = password
            return try result.get()
        }
    }

    // MARK: - Test helpers

    private var keychain: KeychainStore!

    override func setUpWithError() throws {
        let uniqueService = "com.acmebank.okta.tests.\(UUID().uuidString)"
        keychain = KeychainStore(service: uniqueService)
        try scrubAll()
    }

    override func tearDownWithError() throws {
        try scrubAll()
        keychain = nil
    }

    private func scrubAll() throws {
        for key in [KeychainStore.Key.accessToken, .idToken, .refreshToken] {
            try keychain.delete(key)
        }
    }

    /// Base64url encode (no padding) used by `makeJWT`.
    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Build a minimal valid Okta-shaped ID token with the four
    /// claims `IDTokenDecoder` requires.
    private func makeIDToken(
        sub: String = "00uTEST",
        name: String = "Test User",
        email: String = "test@example.com",
        authTime: TimeInterval = 1_700_000_000
    ) throws -> String {
        let payload: [String: Any] = [
            "sub": sub,
            "name": name,
            "email": email,
            "auth_time": authTime
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let header = base64URLEncode(Data(#"{"alg":"RS256","typ":"JWT"}"#.utf8))
        let body = base64URLEncode(payloadData)
        let signature = base64URLEncode(Data("sig".utf8))
        return "\(header).\(body).\(signature)"
    }

    private func makeService(
        flowResult: Result<OktaTokenResult, Error>,
        deviceName: String = "Test Device"
    ) -> (OktaAuthService, FakeDirectAuthFlow) {
        let fake = FakeDirectAuthFlow(result: flowResult)
        let service = OktaAuthService(
            flow: fake,
            keychain: keychain,
            deviceName: { deviceName }
        )
        return (service, fake)
    }

    // MARK: - Success

    func test_signIn_success_returnsExpectedUserSession() async throws {
        let idToken = try makeIDToken(
            sub: "00u123",
            name: "Alex Example",
            email: "alex@example.com",
            authTime: 1_700_000_000
        )
        let tokens = OktaTokenResult(
            accessToken: "access-abc",
            idToken: idToken,
            refreshToken: "refresh-xyz"
        )
        let (service, fake) = makeService(
            flowResult: .success(tokens),
            deviceName: "iPhone 16"
        )

        let session = try await service.signIn(
            username: "alex@example.com",
            password: "p@ssw0rd",
            keepSignedIn: true
        )

        // Username + password flowed unchanged into the flow.
        XCTAssertEqual(fake.capturedUsername, "alex@example.com")
        XCTAssertEqual(fake.capturedPassword, "p@ssw0rd")

        // UserSession composed from ID-token claims + tokens + device.
        XCTAssertEqual(session.userId, "00u123")
        XCTAssertEqual(session.displayName, "Alex Example")
        XCTAssertEqual(session.email, "alex@example.com")
        XCTAssertEqual(session.accessToken, "access-abc")
        XCTAssertEqual(session.authTimestamp.timeIntervalSince1970, 1_700_000_000, accuracy: 0.001)
        XCTAssertEqual(session.deviceName, "iPhone 16")
    }

    func test_signIn_success_writesAccessAndIdTokensToKeychain() async throws {
        let idToken = try makeIDToken()
        let tokens = OktaTokenResult(
            accessToken: "access-abc",
            idToken: idToken,
            refreshToken: "refresh-xyz"
        )
        let (service, _) = makeService(flowResult: .success(tokens))

        _ = try await service.signIn(
            username: "u",
            password: "p",
            keepSignedIn: true
        )

        XCTAssertEqual(try keychain.read(.accessToken), "access-abc")
        XCTAssertEqual(try keychain.read(.idToken), idToken)
    }

    // MARK: - keepSignedIn gating

    func test_signIn_keepSignedInFalse_doesNotPersistRefreshToken() async throws {
        let idToken = try makeIDToken()
        let tokens = OktaTokenResult(
            accessToken: "access-abc",
            idToken: idToken,
            refreshToken: "refresh-xyz"
        )
        let (service, _) = makeService(flowResult: .success(tokens))

        _ = try await service.signIn(
            username: "u",
            password: "p",
            keepSignedIn: false
        )

        XCTAssertNil(
            try keychain.read(.refreshToken),
            "Refresh token must NOT be persisted when keepSignedIn is false"
        )
    }

    func test_signIn_keepSignedInTrue_persistsRefreshToken() async throws {
        let idToken = try makeIDToken()
        let tokens = OktaTokenResult(
            accessToken: "access-abc",
            idToken: idToken,
            refreshToken: "refresh-xyz"
        )
        let (service, _) = makeService(flowResult: .success(tokens))

        _ = try await service.signIn(
            username: "u",
            password: "p",
            keepSignedIn: true
        )

        XCTAssertEqual(try keychain.read(.refreshToken), "refresh-xyz")
    }

    // MARK: - Error mapping

    func test_signIn_credentialRejection_mapsToInvalidCredentials() async throws {
        // Use a domain that is NOT NSURLErrorDomain so the mapper
        // falls through to the .invalidCredentials default \u2014 this
        // is how every Okta credential-rejection error reaches us.
        let oktaError = NSError(
            domain: "com.okta.directauth",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "invalid_grant"]
        )
        let (service, _) = makeService(flowResult: .failure(oktaError))

        do {
            _ = try await service.signIn(
                username: "u",
                password: "wrong",
                keepSignedIn: false
            )
            XCTFail("Expected sign-in to throw")
        } catch let error as OktaAuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Expected OktaAuthError, got \(error)")
        }
    }

    func test_signIn_networkError_mapsToNetwork() async throws {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet
        )
        let (service, _) = makeService(flowResult: .failure(networkError))

        do {
            _ = try await service.signIn(
                username: "u",
                password: "p",
                keepSignedIn: false
            )
            XCTFail("Expected sign-in to throw")
        } catch let error as OktaAuthError {
            XCTAssertEqual(error, .network)
        } catch {
            XCTFail("Expected OktaAuthError, got \(error)")
        }
    }
}
