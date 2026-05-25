import Foundation

/// ViewModel for the Login screen.
///
/// Owns all form-field state, the inline error banner string, and
/// the published `UserSession` produced by a successful Okta
/// sign-in. The actual auth call (`performSignIn()`) lives in
/// `LoginViewModel+Auth.swift` so this file stays focused on
/// view-bound state.
///
/// `LoginViewModel` depends on `OktaAuthenticating` (a protocol),
/// never on the concrete `OktaAuthService`, so tests can supply a
/// stub without touching the OktaDirectAuth SDK or the network.
final class LoginViewModel: ObservableObject {

    // MARK: - Published State

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var keepSignedIn: Bool = false
    @Published var errorMessage: String? = nil

    /// The authenticated session produced by a successful sign-in.
    /// Consumed by the root coordinator (a future PR) to drive the
    /// post-login navigation.
    @Published var session: UserSession? = nil

    // MARK: - Dependencies

    /// Auth service used by `performSignIn()`. Optional so the
    /// no-arg initialiser (used by `LoginView`'s `@StateObject`
    /// default) still works in contexts that haven't wired auth
    /// yet (Xcode previews, the very first launch before coord
    /// wiring lands).
    let auth: OktaAuthenticating?

    // MARK: - Init

    /// Default initialiser. Leaves `auth` nil; only the closure-based
    /// `signIn(onSignIn:)` surface works in this mode.
    init() {
        self.auth = nil
    }

    /// Production initialiser. Inject an `OktaAuthenticating` to
    /// enable `performSignIn()`.
    init(auth: OktaAuthenticating) {
        self.auth = auth
    }

    // MARK: - Computed Properties

    /// `true` when both `username` and `password` are non-empty.
    var isSignInEnabled: Bool {
        !username.isEmpty && !password.isEmpty
    }

    // MARK: - Actions

    /// Invokes `onSignIn` with the current form values.
    ///
    /// Kept for the existing `LoginView` integration surface and
    /// for tests that want to assert the form values flow through
    /// unchanged. The real auth call is `performSignIn()` in the
    /// `+Auth` extension.
    func signIn(onSignIn: (String, String, Bool) -> Void) {
        onSignIn(username, password, keepSignedIn)
    }
}
