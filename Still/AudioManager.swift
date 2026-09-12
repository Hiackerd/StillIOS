import AVFoundation
import Combine

/// Manages the AVAudioSession and plays a near-silent tone during Focus Mode.
///
/// iOS constraints to be aware of:
/// - There is no public API to directly set hardware microphone gain.
/// - The closest we can do is set the input gain via `AVAudioSession.setInputGain(_:)`
///   only when `isInputGainSettable` is true (device-dependent).
/// - A silent tone keeps the audio session "warm" so subsequent sounds play
///   with minimal latency (avoids the hardware ramp-up delay).
@MainActor
final class AudioManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var isFocusModeActive: Bool = false
    @Published private(set) var lastError: String? = nil

    // MARK: - Private
    private let session = AVAudioSession.sharedInstance()
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var toneBuffer: AVAudioPCMBuffer?

    // Silent tone parameters
    // 20 Hz is below the human hearing threshold – keeps the session alive
    // without producing audible sound.
    private let toneSampleRate: Double = 44100
    private let toneFrequency: Double = 20      // Hz – sub-audible
    private let toneAmplitude: Float = 0.001    // near-silent
    private let toneSeconds: Double = 2.0       // looping buffer length

    // MARK: - Public API

    func startFocusMode() {
        lastError = nil
        do {
            try configureSession()
            try buildAndStartEngine()
            playTone()
            isFocusModeActive = true
        } catch {
            lastError = error.localizedDescription
            isFocusModeActive = false
        }
    }

    func stopFocusMode() {
        teardown()
        isFocusModeActive = false
        lastError = nil
    }

    // MARK: - Session Setup

    private func configureSession() throws {
        // .playAndRecord keeps the mic active (needed for hearing device pass-through)
        // .allowBluetooth routes audio to BT hearing aids / AirPods
        // .allowBluetoothA2DP allows A2DP routing as fallback
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
        )

        // Lowest possible I/O buffer: reduces latency significantly on supported hardware.
        // iOS will round up to the nearest supported value (commonly ~5.8 ms on modern iPhones).
        try session.setPreferredIOBufferDuration(0.005)
        try session.setPreferredSampleRate(toneSampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // Attempt to minimise mic input gain (best-effort – hardware-dependent).
        if session.isInputGainSettable {
            try session.setInputGain(0.0)
        }
    }

    // MARK: - AVAudioEngine

    private func buildAndStartEngine() throws {
        let newEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        newEngine.attach(player)

        let format = AVAudioFormat(
            standardFormatWithSampleRate: toneSampleRate,
            channels: 1
        )!

        newEngine.connect(player, to: newEngine.mainMixerNode, format: format)

        toneBuffer = makeToneBuffer(format: format)
        playerNode = player
        engine = newEngine

        try newEngine.start()
    }

    private func playTone() {
        guard let player = playerNode, let buffer = toneBuffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
    }

    // MARK: - Teardown

    private func teardown() {
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        toneBuffer = nil

        // Deactivate session – notifies other apps (e.g. Music) to resume.
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Tone Buffer

    /// Generates a single-cycle sine wave buffer that loops seamlessly.
    private func makeToneBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(toneSampleRate * toneSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let angularFrequency = 2.0 * Double.pi * toneFrequency / toneSampleRate

        for frame in 0..<Int(frameCount) {
            channelData[frame] = Float(sin(Double(frame) * angularFrequency)) * toneAmplitude
        }
        return buffer
    }
}