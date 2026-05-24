import SwiftUI

/// Flat-top hexagon `Shape` used as the Acme Bank logo container.
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let cx = rect.midX
        let cy = rect.midY

        // Flat-top hexagon: 6 corners offset by 30° from a circle
        let r = min(width, height) / 2
        let points: [CGPoint] = (0..<6).map { i in
            let angle = Double(i) * .pi / 3 + .pi / 6 // flat-top: +30°
            return CGPoint(
                x: cx + CGFloat(cos(angle)) * r,
                y: cy + CGFloat(sin(angle)) * r
            )
        }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

/// Acme Bank hexagon logo — navy background with a white "A" overlay.
///
/// Decorative / hidden from VoiceOver.
struct HexagonLogoView: View {

    var body: some View {
        HexagonShape()
            .fill(Color.navyPrimary)
            .frame(width: 64, height: 64)
            .overlay(
                Text("A")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    HexagonLogoView()
        .padding()
}
