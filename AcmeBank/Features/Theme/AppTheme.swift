import SwiftUI

/// Single source of truth for the app-wide colour scheme preference.
///
/// Inject into the SwiftUI environment via `.environmentObject(appTheme)`
/// on the root view, and pair with `.preferredColorScheme(appTheme.colorScheme)`
/// so the system respects the user's in-app selection independently of
/// the OS-level appearance setting.
///
/// Design decision — no persistence:
/// The acceptance criteria explicitly forbid `@AppStorage` usage. Cold
/// launch ALWAYS starts in Light mode; the user's toggle choice lives
/// only in memory for the duration of the session. This is intentional
/// to keep the first-launch experience predictable and to avoid the
/// added complexity of UserDefaults migration.
final class AppTheme: ObservableObject {

    // MARK: - Published State

    /// The currently active colour scheme. Defaults to `.light` on every
    /// cold launch — no persistence, by design.
    @Published var colorScheme: ColorScheme = .light

    // MARK: - Actions

    /// Flips the colour scheme between `.light` and `.dark`.
    func toggle() {
        colorScheme = colorScheme == .light ? .dark : .light
    }
}
