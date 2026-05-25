import XCTest
@testable import AcmeBank

/// Tests for `LoginViewModel.performSignIn()` \u2014 the wiring between
/// the view-model and the injected `OktaAuthenticating` service.
///
/// All tests inject a `StubAuth` so nothing touches the OktaDirectAuth
/// SDK or the network.
@MainActor
final class LoginViewModelAuthTests: XCTestCase {

    // MARK: - Stub

    /// Stub `OktaAuthenticating` that returns the configured result.
    /// Captures the (username, password, keepSignedIn) it was called
    /// with so tests can assert form values flowed through unchanged.
    private final class StubAuth: OktaAuthenticating {
        var result: Result<UserSession, Error>
        private(set) var capturedUsername: String?
        private(set) var capturedPassword: String?
        private(set) var capturedKeepSignedIn: Bool?

        init(result: Result<UserSession, Error>) {
            self.result = result
        }

        func signIn(
            username: String,
            password: String,
            keepSignedIn: Bool
        ) async throws -> UserSession {
            capturedUsername = username
            capturedPassword = password
            capturedKeepSignedIn = keepSignedIn
            return try result.get()
        }
    }

    // MARK: - Helpers

    private func makeSession() -> UserSession {
        UserSession(
            userId: "00u123",
            displayName: "Alex Example",
            email: "alex@example.com",
            accessToken: "access-abc",
            authTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Test Device"
        )
    }

    // MARK: - Success

    func test_performSignIn_success_publishesSessionAndLeavesErrorNil() async {
        let expected = makeSession()
        let stub = StubAuth(result: .success(expected))
        let vm = LoginViewModel(auth: stub)
        vm.username = "alex@example.com"
        vm.password = "p@ssw0rd"
        vm.keepSignedIn = true

        await vm.performSignIn()

        XCTAssertEqual(vm.session, expected, "session must be published on success")
        XCTAssertNil(vm.errorMessage, "errorMessage must remain nil on success")

        // Form values flowed unchanged into the service.
        XCTAssertEqual(stub.capturedUsername, "alex@example.com")
        XCTAssertEqual(stub.capturedPassword, "p@ssw0rd")
        XCTAssertEqual(stub.capturedKeepSignedIn, true)
    }

    // MARK: - Failure mapping (AC: single fixed string for every failure)

    func test_performSignIn_invalidCredentials_publishesACErrorString() async {
        let stub = StubAuth(result: .failure(OktaAuthError.invalidCredentials))
        let vm = LoginViewModel(auth: stub)
        vm.username = "u"
        vm.password = "wrong"

        await vm.performSignIn()

        XCTAssertNil(vm.session, "session must remain nil on failure")
        XCTAssertEqual(
            vm.errorMessage,
            "Incorrect username or password. Please try again.",
            "Per AC, .invalidCredentials must surface the exact banner string"
        )
    }

    func test_performSignIn_networkError_publishesSameACErrorString() async {
        let stub = StubAuth(result: .failure(OktaAuthError.network))
        let vm = LoginViewModel(auth: stub)
        vm.username = "u"
        vm.password = "p"

        await vm.performSignIn()

        XCTAssertNil(vm.session, "session must remain nil on failure")
        XCTAssertEqual(
            vm.errorMessage,
            "Incorrect username or password. Please try again.",
            "Per AC, .network must surface the SAME fixed banner string \u2014 the UI does not distinguish causes"
        )
    }
}
