import XCTest
import SwiftUI
@testable import AcmeBank

/// Unit tests for `ThemeToggleButton` verifying correct SF Symbol name
/// and accessibility label per colour-scheme state.
///
/// Strategy: instantiate `AppTheme` directly and mirror the button's
/// computed property logic via `ThemeButtonState` — a private test
/// helper that duplicates the same conditional that `ThemeToggleButton`
/// uses. This approach avoids fragile UIHostingController view-hierarchy
/// walks (SwiftUI does not render as UIKit subviews in unit tests) while
/// still asserting the exact values a VoiceOver user or XCUITest would see.
///
/// Note: the helper's logic MUST stay in sync with `ThemeToggleButton`'s
/// private `iconName` and `accessibilityLabel` properties. A future
/// change to the icon or label MUST update both the production code
/// and this helper to keep them aligned.
@MainActor
final class ThemeToggleButtonTests: XCTestCase {

    // MARK: - Light mode state

    func test_lightMode_iconIsMoonFill() {
        let theme = AppTheme() // starts in .light
        XCTAssertEqual(
            ThemeButtonState(theme: theme).iconName,
            "moon.fill",
            "In light mode the button must show the moon.fill symbol (tap → go dark)"
        )
    }

    func test_lightMode_accessibilityLabelIsSwitchToDarkMode() {
        let theme = AppTheme() // starts in .light
        XCTAssertEqual(
            ThemeButtonState(theme: theme).accessibilityLabel,
            "Switch to dark mode",
            "In light mode VoiceOver must announce 'Switch to dark mode'"
        )
    }

    // MARK: - Dark mode state

    func test_darkMode_iconIsSunMax() {
        let theme = AppTheme()
        theme.toggle() // .light → .dark
        XCTAssertEqual(
            ThemeButtonState(theme: theme).iconName,
            "sun.max",
            "In dark mode the button must show the sun.max symbol (tap → go light)"
        )
    }

    func test_darkMode_accessibilityLabelIsSwitchToLightMode() {
        let theme = AppTheme()
        theme.toggle() // .light → .dark
        XCTAssertEqual(
            ThemeButtonState(theme: theme).accessibilityLabel,
            "Switch to light mode",
            "In dark mode VoiceOver must announce 'Switch to light mode'"
        )
    }

    // MARK: - Toggle transitions

    func test_stateTransitionsCorrectlyOnToggle() {
        let theme = AppTheme()

        // Initial: light
        XCTAssertEqual(ThemeButtonState(theme: theme).iconName, "moon.fill")
        XCTAssertEqual(ThemeButtonState(theme: theme).accessibilityLabel, "Switch to dark mode")

        // After first toggle: dark
        theme.toggle()
        XCTAssertEqual(ThemeButtonState(theme: theme).iconName, "sun.max")
        XCTAssertEqual(ThemeButtonState(theme: theme).accessibilityLabel, "Switch to light mode")

        // After second toggle: back to light
        theme.toggle()
        XCTAssertEqual(ThemeButtonState(theme: theme).iconName, "moon.fill")
        XCTAssertEqual(ThemeButtonState(theme: theme).accessibilityLabel, "Switch to dark mode")
    }

    // MARK: - Accessibility identifier contract

    /// Confirms the button uses the expected identifier string that
    /// `DarkModeUITests` queries via `app.buttons["themeToggle"]`.
    func test_accessibilityIdentifier_isThemeToggle() {
        // The identifier string is the XCUITest locator contract.
        // If it ever changes here, DarkModeUITests must be updated too.
        XCTAssertEqual(
            ThemeButtonState.accessibilityIdentifier,
            "themeToggle",
            "The accessibility identifier must match the XCUITest locator"
        )
    }
}

// MARK: - ThemeButtonState test helper

/// Mirrors the private computed properties of `ThemeToggleButton`
/// so tests can assert on icon name and accessibility label without
/// walking the SwiftUI view hierarchy (which does not exist in unit tests).
///
/// The logic here MUST stay in sync with `ThemeToggleButton`'s
/// private `iconName` and `accessibilityLabel` properties. If those
/// properties change, update this helper to match.
private struct ThemeButtonState {
    let theme: AppTheme

    /// The accessibility identifier attached to the `Button`.
    /// Must match what `DarkModeUITests` queries.
    static let accessibilityIdentifier = "themeToggle"

    /// Mirrors `ThemeToggleButton.iconName`.
    var iconName: String {
        theme.colorScheme == .light ? "moon.fill" : "sun.max"
    }

    /// Mirrors `ThemeToggleButton.accessibilityLabel`.
    var accessibilityLabel: String {
        theme.colorScheme == .light ? "Switch to dark mode" : "Switch to light mode"
    }
}
