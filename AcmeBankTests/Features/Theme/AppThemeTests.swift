import XCTest
import SwiftUI
@testable import AcmeBank

/// Unit tests for `AppTheme` state transitions and non-persistence guarantee.
///
/// These tests verify:
/// - `colorScheme` initialises to `.light` on every instantiation.
/// - `toggle()` correctly flips `.light` → `.dark`.
/// - A second `toggle()` correctly returns `.dark` → `.light`.
/// - No `UserDefaults` writes occur as a side-effect of `toggle()` calls
///   (persistence is explicitly forbidden by the acceptance criteria).
@MainActor
final class AppThemeTests: XCTestCase {

    // MARK: - Initialisation

    func test_initialColorScheme_isLight() {
        let sut = AppTheme()
        XCTAssertEqual(
            sut.colorScheme,
            .light,
            "AppTheme must initialise to .light on every cold launch"
        )
    }

    // MARK: - toggle()

    func test_toggle_fromLight_flipsToDark() {
        let sut = AppTheme()
        sut.toggle()
        XCTAssertEqual(
            sut.colorScheme,
            .dark,
            "First toggle() from .light must produce .dark"
        )
    }

    func test_toggle_twiceFromLight_returnsToLight() {
        let sut = AppTheme()
        sut.toggle()
        sut.toggle()
        XCTAssertEqual(
            sut.colorScheme,
            .light,
            "Second toggle() must return to .light"
        )
    }

    func test_toggle_threeTimesFromLight_returnsDark() {
        let sut = AppTheme()
        sut.toggle()
        sut.toggle()
        sut.toggle()
        XCTAssertEqual(
            sut.colorScheme,
            .dark,
            "Third toggle() must produce .dark again"
        )
    }

    // MARK: - No UserDefaults persistence

    /// Verifies that `toggle()` calls do NOT write to `UserDefaults`.
    /// The acceptance criteria forbid `@AppStorage` usage; cold launch
    /// must ALWAYS start in Light mode regardless of prior session state.
    func test_toggle_doesNotWriteToUserDefaults() {
        // Snapshot the keys in the standard defaults before we do anything.
        let keysBefore = Set(
            UserDefaults.standard.dictionaryRepresentation().keys
        )

        let sut = AppTheme()
        sut.toggle()  // .light → .dark
        sut.toggle()  // .dark  → .light

        let keysAfter = Set(
            UserDefaults.standard.dictionaryRepresentation().keys
        )

        // No new keys should have been written.
        let newKeys = keysAfter.subtracting(keysBefore)
        XCTAssertTrue(
            newKeys.isEmpty,
            "toggle() must not write to UserDefaults; found new keys: \(newKeys)"
        )
    }

    /// Confirms a freshly created `AppTheme` starts in `.light` even
    /// when an existing instance in the same process is in `.dark`.
    /// (Demonstrates no shared-state or singleton leakage.)
    func test_newInstance_alwaysStartsLight_regardlessOfOtherInstances() {
        let firstInstance = AppTheme()
        firstInstance.toggle() // put it in .dark

        let secondInstance = AppTheme()
        XCTAssertEqual(
            secondInstance.colorScheme,
            .light,
            "A new AppTheme instance must always start in .light, " +
            "regardless of the state of other instances"
        )
    }
}
