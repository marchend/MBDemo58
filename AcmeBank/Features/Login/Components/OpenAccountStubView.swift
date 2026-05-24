import SwiftUI

/// Placeholder destination for the "Open one" link on the login screen.
///
/// Real account-opening flow is deferred to a future story.
struct OpenAccountStubView: View {

    var body: some View {
        VStack(spacing: 8) {
            Text("Open an Account")
                .font(.title2)
                .bold()
            Text("Coming soon")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Open an Account")
    }
}

#Preview {
    OpenAccountStubView()
}
