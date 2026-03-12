import SwiftUI

@main
struct PawdleApp: App {
    // Watch app lifecycle so we can pause/resume looping music cleanly.
    @Environment(\.scenePhase) private var scenePhase
    // Shared app state injected once and consumed by multiple screens.
    @StateObject private var wonWordsStore = WonWordsStore()
    @StateObject private var pawPointsStore = PawPointsStore()
    @State private var showSplash = true
    @State private var splashScheduled = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    StartView()
                        .opacity(showSplash ? 0 : 1)
                        .scaleEffect(showSplash ? 1.03 : 1.0)

                    if showSplash {
                        SplashView()
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
            }
            // Make stores available to the whole navigation tree.
            .environmentObject(wonWordsStore)
            .environmentObject(pawPointsStore)
            .onAppear {
                // Start ambient loop when the app UI first appears.
                SoundManager.shared.startBackgroundMusic()

                // Show mascot intro once, then ease out into home screen.
                guard !splashScheduled else { return }
                splashScheduled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.45)) {
                        showSplash = false
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Keep audio behavior in sync with foreground/background state.
                switch newPhase {
                case .active:
                    SoundManager.shared.resumeBackgroundMusic()
                case .inactive, .background:
                    SoundManager.shared.stopBackgroundMusic()
                @unknown default:
                    break
                }
            }
        }
    }
}
