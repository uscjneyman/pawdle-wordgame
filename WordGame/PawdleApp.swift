import SwiftUI

@main
struct PawdleApp: App {
    // Watch app lifecycle so we can pause/resume looping music cleanly.
    @Environment(\.scenePhase) private var scenePhase
    // Shared app state injected once and consumed by multiple screens.
    @StateObject private var wonWordsStore = WonWordsStore()
    @StateObject private var pawPointsStore = PawPointsStore()
    @StateObject private var authStore = AuthStore()
    @StateObject private var syncStatusStore = SyncStatusStore()
    @StateObject private var communityStore = CommunityStore()
    private let appViewModel = AppViewModel()
    @State private var showSplash = true
    @State private var splashScheduled = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    HomeContainerView()
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
            .environmentObject(authStore)
            .environmentObject(syncStatusStore)
            .environmentObject(communityStore)
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

                if authStore.isAuthenticated {
                    appViewModel.handleOnAppear(
                        authStore: authStore,
                        pawPointsStore: pawPointsStore,
                        wonWordsStore: wonWordsStore,
                        syncStatusStore: syncStatusStore
                    )
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Keep audio behavior in sync with foreground/background state.
                switch newPhase {
                case .active:
                    SoundManager.shared.resumeBackgroundMusic()
                    appViewModel.handleScenePhaseChange(
                        newPhase,
                        authStore: authStore,
                        pawPointsStore: pawPointsStore,
                        wonWordsStore: wonWordsStore,
                        syncStatusStore: syncStatusStore
                    )
                case .inactive, .background:
                    SoundManager.shared.stopBackgroundMusic()
                @unknown default:
                    break
                }
            }
            .onChange(of: authStore.isAuthenticated) { _, authed in
                appViewModel.handleAuthChange(
                    authed,
                    authStore: authStore,
                    pawPointsStore: pawPointsStore,
                    wonWordsStore: wonWordsStore,
                    syncStatusStore: syncStatusStore
                )
            }
            .onChange(of: pawPointsStore.balance) { _, _ in
                appViewModel.handleLocalDataChange(
                    authStore: authStore,
                    pawPointsStore: pawPointsStore,
                    wonWordsStore: wonWordsStore,
                    syncStatusStore: syncStatusStore
                )
            }
            .onChange(of: wonWordsStore.wonWords) { _, _ in
                appViewModel.handleLocalDataChange(
                    authStore: authStore,
                    pawPointsStore: pawPointsStore,
                    wonWordsStore: wonWordsStore,
                    syncStatusStore: syncStatusStore
                )
            }
        }
    }
}
