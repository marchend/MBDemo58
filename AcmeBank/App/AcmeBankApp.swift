import SwiftUI

@main
struct AcmeBankApp: App {

    /// The single source of truth for whether the user is signed in.
    /// `RootCoordinatorView` observes this and switches between the
    /// login screen and the post-auth Landing screen — there is no
    /// other code path that mounts either view, which is how we
    /// enforce "Landing is reachable only through a successful Okta
    /// sign-in".
    @StateObject private var coordinator = RootCoordinator.makeForLaunch()

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView(coordinator: coordinator)
        }
    }
}
