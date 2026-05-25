import Foundation

extension LoginViewModel {

    /// The single inline error string the login banner shows on
    /// any sign-in failure. Per AC the banner copy is FIXED \u2014 we
    /// deliberately do not surface SDK error details to the user.
    static let signInFailureMessage = "Incorrect username or password. Please try again."

    /// Run the Okta direct-auth sign-in using the current form
    /// values, publishing either `session` (on success) or
    /// `errorMessage` (on failure).
    ///
    /// Marked `@MainActor` so the `@Published` writes happen on the
    /// main actor without explicit hops at every call site. The
    /// auth service itself is free to run on any actor \u2014 the
    /// `await` boundary lands us back here on `.main`.
    ///
    /// No-op when `auth` is nil (e.g. `LoginViewModel()` instantiated
    /// from an Xcode preview).
    @MainActor
    func performSignIn() async {
        guard let auth else { return }

        // Clear any prior error so the banner doesn't linger across
        // retries; do NOT clear `session` here because a UI race that
        // re-taps after success should be a no-op, not a regression
        // of the post-login state.
        errorMessage = nil

        do {
            let session = try await auth.signIn(
                username: username,
                password: password,
                keepSignedIn: keepSignedIn
            )
            self.session = session
        } catch {
            // Per AC the banner text is fixed regardless of cause \u2014
            // .invalidCredentials, .network, and .unknown all map
            // to the same single string.
            self.errorMessage = Self.signInFailureMessage
        }
    }
}
