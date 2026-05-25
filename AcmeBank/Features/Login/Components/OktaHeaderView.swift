import SwiftUI

/// Static brand-header strip that mirrors the Okta-hosted login page header.
///
/// Non-interactive / decorative — hidden from VoiceOver.
struct OktaHeaderView: View {

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Leading: lock icon + domain
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("acmebank.okta.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Trailing: Okta logo representation
                HStack(spacing: 2) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.0, green: 0.482, blue: 0.851)) // Okta blue
                    Text("okta")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    OktaHeaderView()
}
