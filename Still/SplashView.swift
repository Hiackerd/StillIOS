import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var ring1Scale: CGFloat = 0.3
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.3
    @State private var ring2Opacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var bgOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(hex: "0A0E1A")
                    .ignoresSafeArea()
                    .opacity(bgOpacity)

                // Ambient glow
                RadialGradient(
                    colors: [
                        Color(hex: "5B8BDF").opacity(0.18),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )
                .ignoresSafeArea()
                .opacity(ring1Opacity)

                // Pulse rings
                Circle()
                    .stroke(Color(hex: "5B8BDF").opacity(0.15), lineWidth: 1)
                    .frame(width: geo.size.width * 0.75)
                    .scaleEffect(ring2Scale)
                    .opacity(ring2Opacity)

                Circle()
                    .stroke(Color(hex: "5B8BDF").opacity(0.25), lineWidth: 1.5)
                    .frame(width: geo.size.width * 0.5)
                    .scaleEffect(ring1Scale)
                    .opacity(ring1Opacity)

                // Center content
                VStack(spacing: 0) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A2140"))
                            .frame(width: 96, height: 96)
                            .shadow(color: Color(hex: "5B8BDF").opacity(0.4), radius: 24, x: 0, y: 0)

                        Image(systemName: "ear.badge.waveform")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "A8C4F0"), Color(hex: "5B8BDF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Spacer().frame(height: 28)

                    // Title
                    VStack(spacing: 6) {
                        Text("still")
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .tracking(12)
                            .foregroundStyle(Color(hex: "E8EFF8"))

                        Text("Hörgeräte · Focus Mode")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color(hex: "A8C4F0").opacity(0.7))
                    }
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                    Spacer()
                }
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        // Background fade
        withAnimation(.easeIn(duration: 0.3)) {
            bgOpacity = 1
        }
        // Logo pop
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.2)) {
            logoScale = 1
            logoOpacity = 1
        }
        // Ring 1
        withAnimation(.easeOut(duration: 0.8).delay(0.35)) {
            ring1Scale = 1
            ring1Opacity = 1
        }
        // Ring 2
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            ring2Scale = 1
            ring2Opacity = 1
        }
        // Title slide up
        withAnimation(.easeOut(duration: 0.5).delay(0.65)) {
            titleOpacity = 1
            titleOffset = 0
        }
    }
}

// MARK: - Color helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    SplashView()
}
