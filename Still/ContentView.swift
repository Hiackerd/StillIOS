import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var hearingDeviceManager: HearingDeviceManager

    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.85
    @State private var breatheScale: CGFloat = 1.0
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background ────────────────────────────────────────────
                Color(hex: "0A0E1A").ignoresSafeArea()

                // Ambient glow when active
                if audioManager.isFocusModeActive {
                    RadialGradient(
                        colors: [
                            Color(hex: "5B8BDF").opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geo.size.width
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.2), value: audioManager.isFocusModeActive)
                }

                // ── Content ───────────────────────────────────────────────
                VStack(spacing: 0) {

                    // Header
                    headerView(geo: geo)
                        .opacity(headerOpacity)
                        .offset(y: headerOffset)

                    Spacer()

                    // Focus button – the visual centrepiece
                    focusButton(geo: geo)
                        .opacity(buttonOpacity)
                        .scaleEffect(buttonScale)

                    Spacer()

                    // Device status card
                    deviceCard(geo: geo)
                        .opacity(cardOpacity)
                        .offset(y: cardOffset)

                    // Bottom safe area spacing
                    Spacer().frame(height: max(geo.safeAreaInsets.bottom, 24))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { runEntrance() }
    }

    // MARK: – Sub-views

    @ViewBuilder
    private func headerView(geo: GeometryProxy) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("still")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(Color(hex: "E8EFF8"))

                Text(audioManager.isFocusModeActive ? "Focus aktiv" : "Bereit")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(
                        audioManager.isFocusModeActive
                            ? Color(hex: "5B8BDF")
                            : Color(hex: "A8C4F0").opacity(0.5)
                    )
                    .animation(.easeInOut(duration: 0.4), value: audioManager.isFocusModeActive)
            }
            Spacer()

            // Mic indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(audioManager.isFocusModeActive ? Color(hex: "5B8BDF") : Color(hex: "1A2140"))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.4), value: audioManager.isFocusModeActive)

                Image(systemName: "mic.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        audioManager.isFocusModeActive
                            ? Color(hex: "A8C4F0")
                            : Color(hex: "A8C4F0").opacity(0.3)
                    )
                    .animation(.easeInOut(duration: 0.4), value: audioManager.isFocusModeActive)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 60)
    }

    @ViewBuilder
    private func focusButton(geo: GeometryProxy) -> some View {
        let size = min(geo.size.width * 0.62, 260.0)

        ZStack {
            // Ripple on activation
            Circle()
                .stroke(Color(hex: "5B8BDF").opacity(rippleOpacity * 0.4), lineWidth: 2)
                .frame(width: size * rippleScale, height: size * rippleScale)

            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "5B8BDF").opacity(audioManager.isFocusModeActive ? 0.6 : 0.15),
                            Color(hex: "A8C4F0").opacity(audioManager.isFocusModeActive ? 0.3 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)
                .scaleEffect(audioManager.isFocusModeActive ? breatheScale : 1.0)

            // Inner fill
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: audioManager.isFocusModeActive ? "1E2D55" : "141828"),
                            Color(hex: audioManager.isFocusModeActive ? "0F1830" : "0A0E1A")
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size * 0.88, height: size * 0.88)
                .shadow(
                    color: Color(hex: "5B8BDF").opacity(audioManager.isFocusModeActive ? 0.35 : 0),
                    radius: 40, x: 0, y: 0
                )

            // Icon + label
            VStack(spacing: 14) {
                Image(systemName: audioManager.isFocusModeActive ? "ear.badge.waveform" : "ear")
                    .font(.system(size: size * 0.18, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: audioManager.isFocusModeActive
                                ? [Color(hex: "A8C4F0"), Color(hex: "5B8BDF")]
                                : [Color(hex: "3A4A6B"), Color(hex: "2A3A5B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.symbolEffect(.replace))

                Text(audioManager.isFocusModeActive ? "Aktiv" : "Tippen zum Starten")
                    .font(.system(size: 13, weight: .light, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(
                        audioManager.isFocusModeActive
                            ? Color(hex: "A8C4F0").opacity(0.8)
                            : Color(hex: "3A4A6B")
                    )
            }
            .animation(.easeInOut(duration: 0.5), value: audioManager.isFocusModeActive)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: audioManager.isFocusModeActive)
        .onTapGesture {
            triggerFocusToggle()
        }
    }

    @ViewBuilder
    private func deviceCard(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Error banner
            if let error = audioManager.lastError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 13))
                    Text(error)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Color(hex: "E8EFF8").opacity(0.7))
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Device card
            HStack(spacing: 0) {
                deviceStatusSection(geo: geo)
                Divider()
                    .frame(height: 36)
                    .background(Color(hex: "A8C4F0").opacity(0.1))
                    .padding(.horizontal, 20)
                sessionStatusSection()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "111827"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "1E2D55"), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func deviceStatusSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "ear.badge.waveform")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color(hex: "5B8BDF").opacity(0.7))
                Text("Hörgerät")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "A8C4F0").opacity(0.5))
            }

            if hearingDeviceManager.pairedDevices.isEmpty {
                Text("Nicht verbunden")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "E8EFF8").opacity(0.4))
            } else {
                ForEach(hearingDeviceManager.pairedDevices, id: \.name) { device in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "5B8BDF"))
                            .frame(width: 5, height: 5)
                        Text(device.name)
                            .font(.system(size: 13, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: "E8EFF8").opacity(0.85))
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sessionStatusSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color(hex: "5B8BDF").opacity(0.7))
                Text("Session")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "A8C4F0").opacity(0.5))
            }

            Text(audioManager.isFocusModeActive ? "Läuft" : "Inaktiv")
                .font(.system(size: 14, weight: .light, design: .rounded))
                .foregroundStyle(
                    audioManager.isFocusModeActive
                        ? Color(hex: "5B8BDF")
                        : Color(hex: "E8EFF8").opacity(0.4)
                )
                .animation(.easeInOut(duration: 0.4), value: audioManager.isFocusModeActive)

            Text("Latenz ~5 ms")
                .font(.system(size: 11, weight: .light, design: .rounded))
                .foregroundStyle(Color(hex: "A8C4F0").opacity(0.3))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Animations

    private func runEntrance() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            headerOpacity = 1
            headerOffset = 0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.25)) {
            buttonOpacity = 1
            buttonScale = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            cardOpacity = 1
            cardOffset = 0
        }
    }

    private func triggerFocusToggle() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        if audioManager.isFocusModeActive {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                audioManager.stopFocusMode()
            }
            stopBreathing()
        } else {
            audioManager.startFocusMode()
            triggerRipple()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startBreathing()
            }
        }
    }

    private func triggerRipple() {
        rippleScale = 1.0
        rippleOpacity = 1.0
        withAnimation(.easeOut(duration: 0.9)) {
            rippleScale = 1.55
            rippleOpacity = 0
        }
    }

    private func startBreathing() {
        guard audioManager.isFocusModeActive else { return }
        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.045
        }
    }

    private func stopBreathing() {
        withAnimation(.easeInOut(duration: 0.4)) {
            breatheScale = 1.0
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioManager())
        .environmentObject(HearingDeviceManager())
}