import XCTest

/// XCUITest covering the complete dark mode toggle user flow.
///
/// Stubbing strategy: honours the same `--use-fake-okta` launch
/// argument used by `LoginToLandingUITests` so we can navigate to
/// the Landing screen (post-auth) without a real Okta tenant.
///
/// AC coverage:
/// - Cold launch starts in Light mode (button label = "Switch to dark mode").
/// - Tapping the toggle button flips to Dark mode (label = "Switch to light mode").
/// - Navigating from Login to Landing carries the shared `AppTheme` state —
///   the Landing screen's toggle also shows Dark mode.
/// - Terminating and relaunching the app resets to Light mode (no persistence).
/// - VoiceOver label updates correctly with each toggle.
final class DarkModeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Creates and configures an `XCUIApplication` with the fake-okta
    /// launch argument and default fake user credentials.
    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--use-fake-okta"]
        app.launchEnvironment["FAKE_OKTA_NAME"] = "Ada Lovelace"
        app.launchEnvironment["FAKE_OKTA_EMAIL"] = "ada@example.com"
        return app
    }

    // MARK: - Tests

    /// Verifies that a cold launch starts in Light mode.
    /// The theme toggle button's accessibility label is "Switch to dark mode"
    /// when the app is in Light mode (it describes the *action*, not the
    /// current state).
    func test_coldLaunch_startsInLightMode() throws {
        let app = makeApp()
        app.launch()

        let toggleButton = app.buttons["themeToggle"]
        XCTAssertTrue(
            toggleButton.waitForExistence(timeout: 5),
            "Theme toggle button must be visible on the login screen"
        )
        XCTAssertEqual(
            toggleButton.label,
            "Switch to dark mode",
            "Cold launch must start in Light mode — toggle label must be 'Switch to dark mode'"
        )
    }

    /// Verifies that tapping the toggle flips the app to Dark mode.
    func test_tapToggle_switchesToDarkMode() throws {
        let app = makeApp()
        app.launch()

        let toggleButton = app.buttons["themeToggle"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 5))

        // Tap to go dark
        toggleButton.tap()

        XCTAssertEqual(
            toggleButton.label,
            "Switch to light mode",
            "After one tap the app must be in Dark mode — label must be 'Switch to light mode'"
        )
    }

    /// Verifies that navigating to the Landing screen preserves the
    /// Dark mode state set on the Login screen (shared `AppTheme`).
    func test_darkModePersistedToLandingScreen() throws {
        let app = makeApp()
        app.launch()

        // Switch to dark mode on the Login screen.
        let toggleButton = app.buttons["themeToggle"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 5))
        toggleButton.tap()
        XCTAssertEqual(toggleButton.label, "Switch to light mode")

        // Sign in to navigate to the Landing screen.
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
        usernameField.tap()
        usernameField.typeText("ada@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("anything")

        app.buttons["Sign in"].tap()

        // Wait for Landing screen.
        let welcome = app.staticTexts["LandingView.welcome"]
        XCTAssertTrue(
            welcome.waitForExistence(timeout: 5),
            "Landing screen must appear after sign-in"
        )

        // The theme toggle on the Landing screen must still show Dark mode.
        let landingToggle = app.buttons["themeToggle"]
        XCTAssertTrue(
            landingToggle.waitForExistence(timeout: 5),
            "Theme toggle must be present on the Landing screen"
        )
        XCTAssertEqual(
            landingToggle.label,
            "Switch to light mode",
            "Landing screen toggle must reflect the Dark mode state set on Login screen"
        )
    }

    /// Verifies that terminating and relaunching the app resets to Light mode.
    /// This confirms there is no `UserDefaults` / `@AppStorage` persistence.
    func test_relaunch_resetsToLightMode() throws {
        let app = makeApp()
        app.launch()

        // Switch to dark mode.
        let toggleButton = app.buttons["themeToggle"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 5))
        toggleButton.tap()
        XCTAssertEqual(toggleButton.label, "Switch to light mode")

        // Terminate the app.
        app.terminate()

        // Relaunch.
        app.launch()

        // The toggle must be back in Light mode.
        let toggleAfterRelaunch = app.buttons["themeToggle"]
        XCTAssertTrue(
            toggleAfterRelaunch.waitForExistence(timeout: 5),
            "Theme toggle must be visible after relaunch"
        )
        XCTAssertEqual(
            toggleAfterRelaunch.label,
            "Switch to dark mode",
            "After relaunch the app must reset to Light mode — no persistence allowed"
        )
    }

    /// Verifies the VoiceOver label updates correctly on each toggle tap.
    func test_voiceOverLabel_updatesOnEachTap() throws {
        let app = makeApp()
        app.launch()

        let toggleButton = app.buttons["themeToggle"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 5))

        // Light mode → label describes action to go dark
        XCTAssertEqual(toggleButton.label, "Switch to dark mode")

        // Tap 1: go dark
        toggleButton.tap()
        XCTAssertEqual(toggleButton.label, "Switch to light mode")

        // Tap 2: go light
        toggleButton.tap()
        XCTAssertEqual(toggleButton.label, "Switch to dark mode")
    }
}
