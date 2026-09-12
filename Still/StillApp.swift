import SwiftUI

@main
struct StillApp: App {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var hearingDeviceManager = HearingDeviceManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    ContentView()
                        .environmentObject(audioManager)
                        .environmentObject(hearingDeviceManager)
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: showSplash)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    showSplash = false
                }
            }
        }
    }
}