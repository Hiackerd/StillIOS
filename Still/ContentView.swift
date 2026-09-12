import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var hearingDeviceManager: HearingDeviceManager

    // Mesh
    @State private var t: CGFloat = 0
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    // Entrance
    @State private var headerOpacity: Double  = 0
    @State private var headerOffset: CGFloat  = -16
    @State private var heroOpacity: Double    = 0
    @State private var heroOffset: CGFloat    = 24
    @State private var cardOpacity: Double    = 0
    @State private var cardOffset: CGFloat    = 24

    // Waveform
    @State private var wavePhase: CGFloat = 0
    private let waveTimer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                meshBackground(geo: geo).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerBar()
                        .opacity(headerOpacity)
                        .offset(y: headerOffset)
                        .padding(.top, geo.safeAreaInsets.top + 16)
                        .padding(.horizontal, 24)

                    Spacer()

                    // Hero – Pill CTA
                    heroPill(geo: geo)
                        .opacity(heroOpacity)
                        .offset(y: heroOffset)
                        .padding(.horizontal, 24)

                    Spacer()

                    // Status card
                    statusCard()
                        .opacity(cardOpacity)
                        .offset(y: cardOffset)
                        .padding(.horizontal, 20)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { runEntrance() }
        .onReceive(timer) { _ in t += 0.007 }
        .onReceive(waveTimer) { _ in
            if audioManager.isFocusModeActive {
                wavePhase += 0.06
            }
        }
    }

    // MARK: – Mesh Background

    @ViewBuilder
    private func meshBackground(geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.14)

            ellipseBlob(
                color: Color(red: 0.18, green: 0.38, blue: 0.82),
                width: w * 0.9, height: w * 0.75,
                x: w * 0.45 + sin(t * 0.6) * w * 0.1,
                y: h * 0.25 + cos(t * 0.5) * h * 0.06
            )
            ellipseBlob(
                color: Color(red: 0.42, green: 0.22, blue: 0.78),
                width: w * 0.7, height: w * 0.65,
                x: w * 0.2 + cos(t * 0.7) * w * 0.1,
                y: h * 0.6 + sin(t * 0.8) * h * 0.07
            )
            ellipseBlob(
                color: Color(red: 0.08, green: 0.55, blue: 0.72),
                width: w * 0.6, height: w * 0.5,
                x: w * 0.8 + sin(t * 0.85) * w * 0.07,
                y: h * 0.72 + cos(t * 0.6) * h * 0.06
            )
        }
        .compositingGroup()
    }

    private func ellipseBlob(
        color: Color, width: CGFloat, height: CGFloat,
        x: CGFloat, y: CGFloat
    ) -> some View {
        Ellipse()
            .fill(color.opacity(0.4))
            .frame(width: width, height: height)
            .blur(radius: 65)
            .position(x: x, y: y)
    }

    // MARK: – Header

    @ViewBuilder
    private func headerBar() -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("still")
                    .font(.system(size: 28, weight: .thin, design: .rounded))
                    .tracking(7)
                    .foregroundStyle(.white)

                Text(audioManager.isFocusModeActive ? "Focus aktiv" : "Bereit")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(
                        audioManager.isFocusModeActive
                            ? .white.opacity(0.85)
                            : .white.opacity(0.35)
                    )
                    .animation(.easeInOut(duration: 0.4), value: audioManager.isFocusModeActive)
            }

            Spacer()

            // Mic glass badge
            HStack(spacing: 5) {
                Circle()
                    .fill(audioManager.isFocusModeActive ? Color.cyan : .white.opacity(0.25))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.4), value: audioManager.isFocusModeActive)

                Image(systemName: "mic.fill")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
        }
    }

    // MARK: – Hero Pill

    @ViewBuilder
    private func heroPill(geo: GeometryProxy) -> some View {
        let isActive = audioManager.isFocusModeActive

        VStack(spacing: 0) {

            // ── Waveform visualisation ────────────────────────────────────
            waveformView(geo: geo, active: isActive)
                .frame(height: 90)
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .clipped()

            Divider()
                .background(.white.opacity(0.1))
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

            // ── Toggle row ────────────────────────────────────────────────
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(isActive ? "Focus Mode läuft" : "Focus Mode")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)

                    Text(isActive
                         ? "Audio-Session aktiv · ~5 ms"
                         : "Tippen zum Aktivieren")
                        .font(.system(size: 12, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .animation(.easeInOut(duration: 0.35), value: isActive)

                Spacer()

                // Custom glass toggle
                glassToggle(isOn: isActive)
                    .onTapGesture { handleToggle() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: isActive ? .cyan.opacity(0.15) : .black.opacity(0.25),
                radius: isActive ? 32 : 24, x: 0, y: 12)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isActive)
    }

    // MARK: – Waveform

    @ViewBuilder
    private func waveformView(geo: GeometryProxy, active: Bool) -> some View {
        GeometryReader { local in
            let w = local.size.width
            let h = local.size.height
            let midY = h / 2

            Canvas { ctx, size in
                let lineCount = 3
                let amplitudes: [CGFloat] = [14, 22, 10]
                let frequencies: [CGFloat] = [1.2, 0.8, 1.6]
                let phaseOffsets: [CGFloat] = [0, .pi * 0.5, .pi]
                let opacities: [Double] = [0.9, 0.5, 0.3]

                for i in 0..<lineCount {
                    var path = Path()
                    let amp = active ? amplitudes[i] : amplitudes[i] * 0.12
                    let freq = frequencies[i]
                    let phase = active ? wavePhase * (1.0 + CGFloat(i) * 0.3) + phaseOffsets[i] : 0

                    path.move(to: CGPoint(x: 0, y: midY))
                    let steps = Int(w / 2)
                    for s in 0...steps {
                        let x = CGFloat(s) * (w / CGFloat(steps))
                        let y = midY + amp * sin(freq * (.pi * 2) * (x / w) + phase)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    ctx.stroke(
                        path,
                        with: .color(.white.opacity(opacities[i])),
                        style: StrokeStyle(
                            lineWidth: i == 1 ? 1.5 : 1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
            .animation(.easeInOut(duration: 0.8), value: active)
        }
    }

    // MARK: – Glass Toggle

    @ViewBuilder
    private func glassToggle(isOn: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(isOn ? Color.cyan.opacity(0.35) : Color.white.opacity(0.1))
                .frame(width: 52, height: 30)
                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))

            Circle()
                .fill(.white)
                .frame(width: 22, height: 22)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .offset(x: isOn ? 11 : -11)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isOn)
    }

    // MARK: – Status Card

    @ViewBuilder
    private func statusCard() -> some View {
        VStack(spacing: 0) {

            // Error
            if let error = audioManager.lastError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 13))
                    Text(error)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Device row
            HStack(spacing: 20) {
                deviceInfo()
                Divider().frame(height: 32).background(.white.opacity(0.12))
                sessionInfo()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 0.5)
                    }
            }
        }
    }

    @ViewBuilder
    private func deviceInfo() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Hörgerät", systemImage: "ear.badge.waveform")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))

            if hearingDeviceManager.pairedDevices.isEmpty {
                Text("Nicht verbunden")
                    .font(.system(size: 13, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            } else {
                ForEach(hearingDeviceManager.pairedDevices, id: \.name) { d in
                    Text(d.name)
                        .font(.system(size: 13, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sessionInfo() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Session", systemImage: "waveform")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))

            Text(audioManager.isFocusModeActive ? "Aktiv" : "Aus")
                .font(.system(size: 13, weight: .light, design: .rounded))
                .foregroundStyle(
                    audioManager.isFocusModeActive ? .cyan : .white.opacity(0.35)
                )
                .animation(.easeInOut(duration: 0.3), value: audioManager.isFocusModeActive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Actions

    private func handleToggle() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if audioManager.isFocusModeActive {
            audioManager.stopFocusMode()
        } else {
            audioManager.startFocusMode()
        }
    }

    private func runEntrance() {
        withAnimation(.easeOut(duration: 0.45).delay(0.05)) {
            headerOpacity = 1; headerOffset = 0
        }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(0.2)) {
            heroOpacity = 1; heroOffset = 0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.4)) {
            cardOpacity = 1; cardOffset = 0
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioManager())
        .environmentObject(HearingDeviceManager())
}