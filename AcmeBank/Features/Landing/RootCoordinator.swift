import Foundation
import SwiftUI

/// Top-of-app coordinator that owns the authenticated `UserSession`
/// and decides which root screen the user sees.
///
/// One source of truth: while `session == nil` the app shows the
/// login screen; once a successful Okta sign-in publishes a
/// `UserSession` the app shows the post-auth Landing screen. There
/// is intentionally no other path to the Landing screen — every
/// non-test build must transit through Okta to populate `session`.
///
/// The coordinator also owns the `OktaAuthenticating` instance, so
/// the composition root can swap in a fake at launch (e.g. via the
/// `--use-fake-okta` launch argument used by `LoginToLandingUITests`)
/// without touching any view code.
@MainActor
final class RootCoordinator: ObservableObject {

    /// Pure data description of which screen `RootCoordinatorView`
    /// should mount. The view's `if let` switch and this enum derive
    /// from the SAME `session` field, so testing this enum proves
    /// the view's branching without needing a SwiftUI snapshot.
    enum RootView: Equatable {
        case login
        case landing(UserSession)
    }

    /// The currently authenticated session, or `nil` when signed out.
    /// `RootCoordinatorView` observes this to swap between the login
    /// screen and the Landing screen.
    @Published var session: UserSession?

    /// Computed view-state used by `RootCoordinatorView` and tests.
    /// `nil` session ⇒ `.login`; any non-nil session ⇒ `.landing`.
    var rootView: RootView {
        if let session {
            return .landing(session)
        }
        return .login
    }

    /// The auth service used when the login screen reports valid
    /// credentials. `nil` when the app launched without Okta env
    /// vars (e.g. an Xcode preview), in which case sign-in is a
    /// no-op rather than a crash.
    let auth: OktaAuthenticating?

    init(auth: OktaAuthenticating?, session: UserSession? = nil) {
        self.auth = auth
        self.session = session
    }

    /// Drive a sign-in attempt from the login screen's `onSignIn`
    /// closure. On success `session` is published and the root view
    /// flips to the Landing screen. Failures are intentionally
    /// silent at the coordinator layer — the login-screen banner is
    /// owned by `LoginViewModel.performSignIn()` (PR 3) and a future
    /// PR will close the gap by routing the VM-driven path through
    /// here. For this PR the closure surface exists solely to drive
    /// the happy path to the Landing screen.
    func signIn(
        username: String,
        password: String,
        keepSignedIn: Bool
    ) {
        guard let auth else {
            // No auth wired (preview / launch-without-config). The
            // closure-only LoginView path is still callable but
            // produces no session — exactly the legacy behaviour.
            return
        }
        Task { @MainActor in
            do {
                let newSession = try await auth.signIn(
                    username: username,
                    password: password,
                    keepSignedIn: keepSignedIn
                )
                self.session = newSession
            } catch {
                // Swallowed by design — see doc-comment above.
            }
        }
    }
}

// MARK: - Composition root

/// SwiftUI view that renders the appropriate root screen for the
/// current auth state. Mounted directly inside `AcmeBankApp`'s
/// `WindowGroup` — there is no other path to either child screen.
struct RootCoordinatorView: View {

    @ObservedObject var coordinator: RootCoordinator

    var body: some View {
        Group {
            switch coordinator.rootView {
            case .landing(let session):
                LandingView(session: session)
            case .login:
                LoginView(onSignIn: { username, password, keepSignedIn in
                    coordinator.signIn(
                        username: username,
                        password: password,
                        keepSignedIn: keepSignedIn
                    )
                })
            }
        }
    }
}

// MARK: - Composition helpers

extension RootCoordinator {

    /// Build the coordinator that backs the real `@main` app at
    /// launch. Honours the `--use-fake-okta` launch argument by
    /// substituting a deterministic in-memory auth service, so the
    /// XCUITest can exercise the login→landing flow without an Okta
    /// tenant or a network. The fake path is GATED on the launch
    /// arg — no production build path can reach it.
    static func makeForLaunch(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> RootCoordinator {
        if arguments.contains("--use-fake-okta") {
            return RootCoordinator(auth: FakeLaunchAuth.fromEnvironment(environment))
        }
        // Real path: read Okta config from the Info.plist values
        // injected at build time. `fromBundle()` traps if env vars
        // are missing, which is the documented behaviour.
        let config = OktaConfig.fromBundle()
        return RootCoordinator(auth: OktaAuthService(config: config))
    }
}

/// Fake `OktaAuthenticating` used only when the app launches with
/// `--use-fake-okta`. Returns a deterministic `UserSession` so the
/// XCUITest can assert on a known welcome string without standing
/// up an Okta tenant. Lives next to the coordinator so the gating
/// (and the fact that it is the ONLY non-Okta sign-in path) is
/// reviewable in one file.
struct FakeLaunchAuth: OktaAuthenticating {
    let session: UserSession

    func signIn(
        username: String,
        password: String,
        keepSignedIn: Bool
    ) async throws -> UserSession {
        session
    }

    /// Build the fake from optional `FAKE_OKTA_*` env vars so the
    /// UI test can override the displayed name / email. Falls back
    /// to a fixed user otherwise.
    static func fromEnvironment(_ env: [String: String]) -> FakeLaunchAuth {
        FakeLaunchAuth(
            session: UserSession(
                userId: env["FAKE_OKTA_SUB"] ?? "fake-sub",
                displayName: env["FAKE_OKTA_NAME"] ?? "Ada Lovelace",
                email: env["FAKE_OKTA_EMAIL"] ?? "ada@example.com",
                accessToken: "fake-access-token",
                authTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
                deviceName: "UITest Device"
            )
        )
    }
}
