import SwiftUI

struct SplashView: View {

    // Mesh animation
    @State private var t: CGFloat = 0
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    // Entrance states
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity: Double = 0
    @State private var cardBlur: CGFloat = 20
    @State private var iconOffset: CGFloat = 8
    @State private var iconOpacity: Double = 0
    @State private var labelOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Animated mesh background ──────────────────────────────
                animatedBackground(geo: geo)
                    .ignoresSafeArea()

                // ── Floating glass card ───────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()

                    glassCard(geo: geo)
                        .offset(y: cardOffset)
                        .opacity(cardOpacity)
                        .blur(radius: cardBlur)

                    Spacer()
                        .frame(height: geo.size.height * 0.12)
                }
            }
        }
        .onAppear { runEntrance() }
        .onReceive(timer) { _ in
            t += 0.008
        }
    }

    // MARK: – Background

    @ViewBuilder
    private func animatedBackground(geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height

        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.14)

            // Blob 1 – blau
            ellipseBlob(
                color: Color(red: 0.18, green: 0.38, blue: 0.82),
                width: w * 0.85,
                height: w * 0.7,
                x: w * 0.5 + sin(t * 0.7) * w * 0.12,
                y: h * 0.28 + cos(t * 0.5) * h * 0.06
            )
            // Blob 2 – violett
            ellipseBlob(
                color: Color(red: 0.42, green: 0.22, blue: 0.78),
                width: w * 0.65,
                height: w * 0.6,
                x: w * 0.25 + cos(t * 0.6) * w * 0.1,
                y: h * 0.58 + sin(t * 0.8) * h * 0.08
            )
            // Blob 3 – türkis
            ellipseBlob(
                color: Color(red: 0.08, green: 0.55, blue: 0.72),
                width: w * 0.55,
                height: w * 0.45,
                x: w * 0.78 + sin(t * 0.9) * w * 0.08,
                y: h * 0.7 + cos(t * 0.55) * h * 0.07
            )
        }
        .compositingGroup()
    }

    private func ellipseBlob(
        color: Color,
        width: CGFloat,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        Ellipse()
            .fill(color.opacity(0.45))
            .frame(width: width, height: height)
            .blur(radius: 70)
            .position(x: x, y: y)
    }

    // MARK: – Glass Card

    @ViewBuilder
    private func glassCard(geo: GeometryProxy) -> some View {
        VStack(spacing: 20) {

            // Icon
            Image(systemName: "waveform.and.magnifyingglass")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: iconOffset)
                .opacity(iconOpacity)

            // Wordmark
            VStack(spacing: 5) {
                Text("still")
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .tracking(14)
                    .foregroundStyle(.white)

                Text("Hörgeräte · Focus Mode")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .opacity(labelOpacity)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 44)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    // Top highlight — the hallmark of glass
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 20)
        .padding(.horizontal, 40)
    }

    // MARK: – Entrance

    private func runEntrance() {
        withAnimation(.spring(response: 0.75, dampingFraction: 0.72).delay(0.15)) {
            cardOffset = 0
            cardOpacity = 1
            cardBlur = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            iconOffset = 0
            iconOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.6)) {
            labelOpacity = 1
        }
    }
}

// MARK: - Color hex helper (shared)
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >>  8) & 0xFF) / 255,
            blue:  Double( v        & 0xFF) / 255
        )
    }
}

#Preview { SplashView() }