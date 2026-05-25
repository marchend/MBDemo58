import XCTest

/// XCUITest covering the happy-path navigation from the login screen
/// to the post-auth Landing screen.
///
/// Stubbing strategy: the app honours the `--use-fake-okta` launch
/// argument by swapping in a deterministic `FakeLaunchAuth` (see
/// `RootCoordinator.makeForLaunch`). The fake's user details are
/// overrideable via `FAKE_OKTA_NAME` / `FAKE_OKTA_EMAIL` environment
/// variables, so this test pins exact strings ("Ada Lovelace" /
/// "ada@example.com") and asserts the Landing screen renders them
/// verbatim. No Okta tenant or network is required for this test
/// to run on a clean simulator.
///
/// AC coverage:
/// - login → landing happy path,
/// - welcome text driven by the "ID-token" claims (here: the fake's
///   `displayName` / `email`),
/// - login screen is NOT visible after a successful sign-in.
final class LoginToLandingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_signIn_navigatesToLandingWithGreetingFromTokenClaims() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--use-fake-okta"]
        app.launchEnvironment["FAKE_OKTA_NAME"] = "Ada Lovelace"
        app.launchEnvironment["FAKE_OKTA_EMAIL"] = "ada@example.com"
        app.launch()

        // Sanity check: the login screen is visible before sign-in.
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(
            usernameField.waitForExistence(timeout: 5),
            "Login screen must be visible on launch when session is nil"
        )

        // Enter credentials. The fake auth ignores the values, but
        // the form-validation gate requires both fields to be non-empty
        // before the "Sign in" button enables.
        usernameField.tap()
        usernameField.typeText("ada@example.com")

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists, "Password field must exist on the login screen")
        passwordField.tap()
        passwordField.typeText("anything")

        // Tap "Sign in".
        let signInButton = app.buttons["Sign in"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 2))
        signInButton.tap()

        // Landing screen appears with the dynamic greeting driven by
        // the fake's ID-token claims.
        let welcome = app.staticTexts["LandingView.welcome"]
        XCTAssertTrue(
            welcome.waitForExistence(timeout: 5),
            "Landing screen must appear after a successful sign-in"
        )
        XCTAssertEqual(
            welcome.label,
            "Welcome, Ada Lovelace",
            "Welcome headline must come verbatim from the (faked) ID-token displayName"
        )

        let emailLabel = app.staticTexts["LandingView.email"]
        XCTAssertTrue(emailLabel.exists, "Landing screen must render the email line")
        XCTAssertEqual(
            emailLabel.label,
            "ada@example.com",
            "Email line must come verbatim from the (faked) ID-token email claim"
        )

        // And the login form is gone — there is no path back to it
        // while the session is non-nil.
        XCTAssertFalse(
            usernameField.exists,
            "Login form must not be visible after a successful sign-in"
        )
    }
}
