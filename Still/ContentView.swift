import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var hearingDeviceManager: HearingDeviceManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {

                // MARK: Hearing Device Status
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hörgerät / CI", systemImage: "ear.badge.waveform")
                            .font(.headline)

                        if hearingDeviceManager.pairedDevices.isEmpty {
                            Text("Kein unterstütztes Gerät verbunden")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(hearingDeviceManager.pairedDevices, id: \.name) { device in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .font(.subheadline)
                                        Text(device.category.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: Focus Mode Toggle
                GroupBox {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focus Mode")
                                    .font(.headline)
                                Text(audioManager.isFocusModeActive
                                     ? "Aktiv – Audio-Session läuft"
                                     : "Inaktiv")
                                    .font(.caption)
                                    .foregroundStyle(audioManager.isFocusModeActive ? .green : .secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { audioManager.isFocusModeActive },
                                set: { newValue in
                                    if newValue {
                                        audioManager.startFocusMode()
                                    } else {
                                        audioManager.stopFocusMode()
                                    }
                                }
                            ))
                            .labelsHidden()
                        }

                        if let error = audioManager.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // MARK: Mic Level Info
                if audioManager.isFocusModeActive {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Mikrofon", systemImage: "mic.fill")
                                .font(.headline)
                            Text("Pegel auf Minimum gesetzt (iOS-Limit: Softwarepegel, kein direkter Hardwarezugriff)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Still")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioManager())
        .environmentObject(HearingDeviceManager())
}