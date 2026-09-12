import AVFoundation
import Combine

/// Manages the AVAudioSession and plays a near-silent tone during Focus Mode.
///
/// iOS constraints:
/// - No public API for direct hardware mic gain → `setInputGain` only when `isInputGainSettable`
/// - Silent 20 Hz tone keeps the audio session "warm" to minimise hardware ramp-up latency
@MainActor
final class AudioManager: ObservableObject {

    @Published private(set) var isFocusModeActive: Bool = false
    @Published private(set) var lastError: String? = nil

    private let session = AVAudioSession.sharedInstance()
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var toneBuffer: AVAudioPCMBuffer?

    private let toneSampleRate: Double = 44100
    private let toneFrequency: Double = 20       // Hz – sub-audible
    private let toneAmplitude: Float  = 0.001    // near-silent
    private let toneSeconds: Double   = 2.0

    // MARK: - Public

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

    // MARK: - Session

    private func configureSession() throws {
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
        )
        try session.setPreferredIOBufferDuration(0.005)
        try session.setPreferredSampleRate(toneSampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        if session.isInputGainSettable {
            try session.setInputGain(0.0)
        }
    }

    // MARK: - Engine

    private func buildAndStartEngine() throws {
        let newEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        newEngine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: toneSampleRate, channels: 1)!
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
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Tone Buffer

    private func makeToneBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(toneSampleRate * toneSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = frameCount
        let omega = 2.0 * Double.pi * toneFrequency / toneSampleRate
        for frame in 0..<Int(frameCount) {
            channelData[frame] = Float(sin(Double(frame) * omega)) * toneAmplitude
        }
        return buffer
    }
}