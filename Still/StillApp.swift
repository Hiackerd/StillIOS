import SwiftUI

@main
struct StillApp: App {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var hearingDeviceManager = HearingDeviceManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(hearingDeviceManager)
        }
    }
}