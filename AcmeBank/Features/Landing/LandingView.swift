import SwiftUI

/// Post-authentication Landing screen.
///
/// Displays the dynamic welcome greeting populated from the
/// `UserSession` ID-token claims published by the login flow. By
/// design this view holds NO other UI — the full home/dashboard is
/// out of scope for this PR. There are deliberately no hardcoded
/// user-facing strings and no second network call: every visible
/// value comes from the `UserSession` passed in by the root
/// coordinator.
struct LandingView: View {

    /// The authenticated session built from the ID token in the
    /// auth layer. The view treats it as read-only data.
    let session: UserSession

    // MARK: - Derived strings (testable)

    /// Headline string the view renders. Pure function of the
    /// session's `displayName`; exposed so unit tests can assert
    /// the AC-mandated "Welcome, {name}" format without needing a
    /// SwiftUI snapshot harness.
    var welcomeText: String {
        "Welcome, \(session.displayName)"
    }

    /// Email string the view renders directly below the headline.
    /// Pure pass-through of `session.email` — kept as a property so
    /// tests have a stable, testable surface alongside `welcomeText`.
    var emailText: String {
        session.email
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            Text(welcomeText)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("LandingView.welcome")

            Text(emailText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("LandingView.email")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityIdentifier("LandingView")
    }
}

#Preview {
    LandingView(
        session: UserSession(
            userId: "preview-sub",
            displayName: "Ada Lovelace",
            email: "ada@example.com",
            accessToken: "preview-access-token",
            authTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Preview Device"
        )
    )
}
