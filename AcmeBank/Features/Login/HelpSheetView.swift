import SafariServices
import SwiftUI

/// `UIViewControllerRepresentable` that wraps `SFSafariViewController`
/// to display the Okta support URL inside the app.
private struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// Sheet content that presents the Acme Bank Okta support page.
///
/// Presented as a `.sheet` from `LoginView` when the user taps "Need help?".
struct HelpSheetView: View {

    // swiftlint:disable:next force_unwrapping
    private let supportURL = URL(string: "https://support.acmebank.okta.com")!

    var body: some View {
        SafariView(url: supportURL)
            .ignoresSafeArea()
    }
}

#Preview {
    HelpSheetView()
}
