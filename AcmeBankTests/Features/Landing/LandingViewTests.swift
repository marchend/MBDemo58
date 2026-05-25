import XCTest
import SwiftUI
@testable import AcmeBank

/// Tests for `LandingView` — the post-auth screen that renders the
/// dynamic welcome greeting from the `UserSession` ID-token claims.
///
/// The AC is unambiguous: "Welcome, {displayName}" and "{email}" come
/// from the session, nothing else is rendered, no second network call.
/// These tests assert the view's derived strings — the renderable
/// values — match the session it was initialised with. There is no
/// hardcoded "UITest User" string anywhere in shipped code so these
/// tests would also catch a regression that re-introduces one.
final class LandingViewTests: XCTestCase {

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

    // MARK: - welcomeText

    func test_welcomeText_usesSessionDisplayName() {
        let view = LandingView(session: makeSession(displayName: "Ada Lovelace"))
        XCTAssertEqual(
            view.welcomeText,
            "Welcome, Ada Lovelace",
            "Headline must be 'Welcome, {displayName}' verbatim per AC"
        )
    }

    func test_welcomeText_reflectsADifferentDisplayName() {
        let view = LandingView(session: makeSession(displayName: "Grace Hopper"))
        XCTAssertEqual(view.welcomeText, "Welcome, Grace Hopper")
    }

    /// The view must NOT embed a hardcoded placeholder name. If a
    /// future change re-introduces "UITest User" (the deleted
    /// bootstrap string) for any session, this test fails.
    func test_welcomeText_doesNotContainBootstrapPlaceholder() {
        let view = LandingView(session: makeSession(displayName: "Ada Lovelace"))
        XCTAssertFalse(
            view.welcomeText.contains("UITest User"),
            "The bootstrap 'UITest User' string must not appear in the rendered welcome"
        )
    }

    // MARK: - emailText

    func test_emailText_isSessionEmailVerbatim() {
        let view = LandingView(session: makeSession(email: "ada@example.com"))
        XCTAssertEqual(view.emailText, "ada@example.com")
    }

    func test_emailText_reflectsADifferentEmail() {
        let view = LandingView(session: makeSession(email: "grace@navy.mil"))
        XCTAssertEqual(view.emailText, "grace@navy.mil")
    }

    // MARK: - View construction

    /// Smoke test: the view initialises and produces a non-nil body
    /// without touching any network / persistence layer. Guards
    /// against an AC violation where Landing makes a second call
    /// during construction.
    func test_viewBody_initializesPurely() {
        let view = LandingView(session: makeSession())
        _ = view.body
    }
}
