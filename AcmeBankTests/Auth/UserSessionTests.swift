import XCTest
@testable import AcmeBank

final class UserSessionTests: XCTestCase {

    private func makeSession(
        userId: String = "u-1",
        displayName: String = "Test User",
        email: String = "test@example.com",
        accessToken: String = "access-token-value",
        authTimestamp: Date = Date(timeIntervalSince1970: 1_700_000_000),
        deviceName: String = "Test iPhone"
    ) -> UserSession {
        UserSession(
            userId: userId,
            displayName: displayName,
            email: email,
            accessToken: accessToken,
            authTimestamp: authTimestamp,
            deviceName: deviceName
        )
    }

    func test_codableRoundTrip_preservesAllFields() throws {
        let original = makeSession()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(UserSession.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.userId, "u-1")
        XCTAssertEqual(decoded.displayName, "Test User")
        XCTAssertEqual(decoded.email, "test@example.com")
        XCTAssertEqual(decoded.accessToken, "access-token-value")
        XCTAssertEqual(decoded.authTimestamp.timeIntervalSince1970, 1_700_000_000, accuracy: 0.001)
        XCTAssertEqual(decoded.deviceName, "Test iPhone")
    }

    func test_equatable_identicalSessionsCompareEqual() {
        XCTAssertEqual(makeSession(), makeSession())
    }

    func test_equatable_differentUserId_compareUnequal() {
        XCTAssertNotEqual(makeSession(userId: "u-1"), makeSession(userId: "u-2"))
    }

    func test_equatable_differentAccessToken_compareUnequal() {
        XCTAssertNotEqual(
            makeSession(accessToken: "token-A"),
            makeSession(accessToken: "token-B")
        )
    }

    func test_equatable_differentAuthTimestamp_compareUnequal() {
        XCTAssertNotEqual(
            makeSession(authTimestamp: Date(timeIntervalSince1970: 1)),
            makeSession(authTimestamp: Date(timeIntervalSince1970: 2))
        )
    }
}
