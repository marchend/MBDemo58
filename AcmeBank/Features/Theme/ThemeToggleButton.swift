import SwiftUI

/// A reusable toolbar button that toggles the app-wide colour scheme
/// between Light and Dark mode.
///
/// **Usage** — place in any view whose subtree has access to `AppTheme`
/// via `.environmentObject(appTheme)`:
///
/// ```swift
/// .overlay(alignment: .topTrailing) { ThemeToggleButton() }
/// ```
///
/// **Accessibility** — the inner `Button` carries both
/// `.accessibilityLabel(…)` (VoiceOver announcement) and
/// `.accessibilityIdentifier("themeToggle")` (XCUITest locator).
/// These are intentionally on the `Button` only — attaching them to
/// the outer `View` body would collapse the accessibility element and
/// break XCUITest queries.
///
/// **Touch target** — the button frame is pinned to ≥ 44×44 pt per
/// Apple's HIG, ensuring it meets WCAG 2.5.5 (target size).
struct ThemeToggleButton: View {

    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        Button {
            appTheme.toggle()
        } label: {
            Image(systemName: iconName)
                .imageScale(.large)
        }
        .frame(minWidth: 44, minHeight: 44)
        .padding(8)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("themeToggle")
    }

    // MARK: - Private helpers

    /// SF Symbol name that represents the *target* state (tapping reaches).
    /// Showing a moon means "tap to go dark"; showing a sun means "tap to go light".
    private var iconName: String {
        appTheme.colorScheme == .light ? "moon.fill" : "sun.max"
    }

    /// VoiceOver label describing the *action* the button will perform.
    private var accessibilityLabel: String {
        appTheme.colorScheme == .light ? "Switch to dark mode" : "Switch to light mode"
    }
}

// MARK: - Preview

#Preview {
    ThemeToggleButton()
        .environmentObject(AppTheme())
        .padding()
}
