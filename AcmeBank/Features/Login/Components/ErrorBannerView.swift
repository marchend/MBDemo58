import SwiftUI

/// Inline error banner displayed below the password field.
///
/// Uses `opacity` to show/hide so the layout stays stable and avoids
/// vertical jumps when the error message appears or disappears.
struct ErrorBannerView: View {

    let message: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(message ?? "")
                .font(.subheadline)
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .frame(minHeight: 20)
        .opacity(message == nil ? 0 : 1)
        .accessibilityHidden(message == nil)
    }
}

#Preview {
    VStack(spacing: 16) {
        ErrorBannerView(message: "Incorrect username or password. Please try again.")
        ErrorBannerView(message: nil)
    }
    .padding()
}
