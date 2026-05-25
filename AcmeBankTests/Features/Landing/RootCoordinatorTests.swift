import XCTest
@testable import AcmeBank

/// Tests for `RootCoordinator` — the state machine that decides
/// whether the app shows the login screen or the post-auth Landing
/// screen. The AC for PR 4 is "Landing is reachable ONLY through a
/// successful Okta sign-in; session == nil always shows the login
/// screen", so these tests pin both directions of the toggle.
@MainActor
final class RootCoordinatorTests: XCTestCase {

    // MARK: - Stub

    /// Stub `OktaAuthenticating` that returns the configured result
    /// without touching the SDK or the network. Mirrors the stub
    /// used in `LoginViewModelAuthTests` so the two test files share
    /// the same fake-auth pattern.
    private final class StubAuth: OktaAuthenticating {
        var result: Result<UserSession, Error>

        init(result: Result<UserSession, Error>) {
            self.result = result
        }

        func signIn(
            username: String,
            password: String,
            keepSignedIn: Bool
        ) async throws -> UserSession {
            try result.get()
        }
    }

    // MARK: - Helpers

    private func makeSession(
        displayName: String = "Ada Lovelace",
        email: String = "ada@example.com"
    ) -> UserSession {
        UserSession(
            userId: "00uTEST",
            displayName: displayName,
            email: email,
            accessToken: "access-token",
            authTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Test Device"
        )
    }

    // MARK: - rootView toggle (AC: session presence drives the root)

    func test_rootView_isLoginWhenSessionIsNil() {
        let coordinator = RootCoordinator(auth: nil, session: nil)
        XCTAssertEqual(coordinator.rootView, .login)
    }

    func test_rootView_isLandingWhenSessionIsSet() {
        let session = makeSession()
        let coordinator = RootCoordinator(auth: nil, session: session)
        XCTAssertEqual(coordinator.rootView, .landing(session))
    }

    func test_rootView_flipsFromLoginToLandingWhenSessionPublished() {
        let coordinator = RootCoordinator(auth: nil, session: nil)
        XCTAssertEqual(coordinator.rootView, .login, "starts on login")

        let session = makeSession()
        coordinator.session = session

        XCTAssertEqual(
            coordinator.rootView,
            .landing(session),
            "publishing a session must flip the root view to landing"
        )
    }

    func test_rootView_flipsBackToLoginWhenSessionCleared() {
        let coordinator = RootCoordinator(auth: nil, session: makeSession())
        XCTAssertEqual(coordinator.rootView, .landing(makeSession()), "starts on landing")

        coordinator.session = nil

        XCTAssertEqual(
            coordinator.rootView,
            .login,
            "clearing the session must return the root view to login"
        )
    }

    // MARK: - signIn drives the toggle via the auth service

    func test_signIn_success_publishesSessionAndFlipsRootViewToLanding() async {
        let expected = makeSession(displayName: "Grace Hopper", email: "grace@navy.mil")
        let stub = StubAuth(result: .success(expected))
        let coordinator = RootCoordinator(auth: stub)
        XCTAssertEqual(coordinator.rootView, .login)

        coordinator.signIn(username: "grace", password: "p", keepSignedIn: false)
        await waitUntil(timeout: 1.0) { coordinator.session != nil }

        XCTAssertEqual(coordinator.session, expected)
        XCTAssertEqual(coordinator.rootView, .landing(expected))
    }

    func test_signIn_failure_leavesSessionNilAndRootViewOnLogin() async {
        let stub = StubAuth(result: .failure(OktaAuthError.invalidCredentials))
        let coordinator = RootCoordinator(auth: stub)

        coordinator.signIn(username: "u", password: "wrong", keepSignedIn: false)
        // Give the Task one run-loop turn to complete.
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(coordinator.session, "failed sign-in must NOT publish a session")
        XCTAssertEqual(
            coordinator.rootView,
            .login,
            "failed sign-in must leave the root view on the login screen"
        )
    }

    func test_signIn_withoutAuth_isNoOp() async {
        let coordinator = RootCoordinator(auth: nil)
        coordinator.signIn(username: "u", password: "p", keepSignedIn: false)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNil(coordinator.session)
        XCTAssertEqual(coordinator.rootView, .login)
    }

    // MARK: - makeForLaunch composition root

    func test_makeForLaunch_withFakeOktaArg_buildsFakeAuthCoordinator() {
        let coordinator = RootCoordinator.makeForLaunch(
            arguments: ["acmebank", "--use-fake-okta"],
            environment: [
                "FAKE_OKTA_NAME": "Test Persona",
                "FAKE_OKTA_EMAIL": "persona@example.com"
            ]
        )
        XCTAssertNil(coordinator.session, "launch coordinator starts unauthenticated")
        XCTAssertEqual(coordinator.rootView, .login)
        XCTAssertTrue(
            coordinator.auth is FakeLaunchAuth,
            "with --use-fake-okta the launch path must wire the fake auth service"
        )
    }

    // MARK: - Helpers

    /// Spin the main run loop until `condition()` is true or
    /// `timeout` elapses. The coordinator's `signIn` dispatches the
    /// auth call as a `Task`; tests need to give it a chance to
    /// complete before asserting on the published session.
    private func waitUntil(
        timeout: TimeInterval,
        condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
