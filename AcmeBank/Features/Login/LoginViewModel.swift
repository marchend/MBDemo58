import Foundation

/// ViewModel for the Login screen.
///
/// Owns all form-field state and the sole sign-in integration surface
/// (`signIn(onSignIn:)`). No auth, networking, or Keychain code lives here —
/// those concerns belong in a future `AuthService` (deferred).
final class LoginViewModel: ObservableObject {

    // MARK: - Published State

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var keepSignedIn: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Computed Properties

    /// `true` when both `username` and `password` are non-empty.
    var isSignInEnabled: Bool {
        !username.isEmpty && !password.isEmpty
    }

    // MARK: - Actions

    /// Invokes `onSignIn` with the current form values.
    ///
    /// This is the only integration surface for sign-in. The caller is
    /// responsible for wiring the real auth flow (deferred to the Okta
    /// integration PR).
    func signIn(onSignIn: (String, String, Bool) -> Void) {
        onSignIn(username, password, keepSignedIn)
    }
}
