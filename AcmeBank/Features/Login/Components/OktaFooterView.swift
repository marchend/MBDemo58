import SwiftUI

/// Static "Secured by ● okta" footer strip.
///
/// Decorative / hidden from VoiceOver.
struct OktaFooterView: View {

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 4) {
                Text("Secured by")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Image(systemName: "circle.fill")
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.0, green: 0.482, blue: 0.851)) // Okta blue
                Text("okta")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    OktaFooterView()
}
