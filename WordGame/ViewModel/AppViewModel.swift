import Foundation
import SwiftUI

@MainActor
final class AppViewModel {
    private let playerDataService: SupabasePlayerDataService
    private var syncTask: Task<Void, Never>?
    private var isApplyingRemoteSnapshot = false

    init(playerDataService: SupabasePlayerDataService) {
        self.playerDataService = playerDataService
    }

    convenience init() {
        self.init(playerDataService: SupabasePlayerDataService())
    }

    func handleOnAppear(
        authStore: AuthStore,
        pawPointsStore: PawPointsStore,
        wonWordsStore: WonWordsStore,
        syncStatusStore: SyncStatusStore
    ) {
        guard authStore.isAuthenticated else { return }
        refreshFromCloud(
            authStore: authStore,
            pawPointsStore: pawPointsStore,
            wonWordsStore: wonWordsStore,
            syncStatusStore: syncStatusStore
        )
        scheduleCloudSync(
            authStore: authStore,
            pawPointsStore: pawPointsStore,
            wonWordsStore: wonWordsStore,
            syncStatusStore: syncStatusStore
        )
    }

    func handleScenePhaseChange(
        _ newPhase: ScenePhase,
        authStore: AuthStore,
        pawPointsStore: PawPointsStore,
        wonWordsStore: WonWordsStore,
        syncStatusStore: SyncStatusStore
    ) {
        guard newPhase == .active else { return }
        guard authStore.isAuthenticated else { return }

        refreshFromCloud(
            authStore: authStore,
            pawPointsStore: pawPointsStore,
            wonWordsStore: wonWordsStore,
            syncStatusStore: syncStatusStore
        )
        scheduleCloudSync(
            authStore: authStore,
            pawPointsStore: pawPointsStore,
            wonWordsStore: wonWordsStore,
            syncStatusStore: syncStatusStore
        )
    }

    func handleAuthChange(
        _ isAuthenticated: Bool,
        authStore: AuthStore,
        pawPointsStore: PawPointsStore,
        wonWordsStore: WonWordsStore,
        syncStatusStore: SyncStatusStore
    ) {
        if isAuthenticated {
            refreshFromCloud(
                authStore: authStore,
                pawPointsStore: pawPointsStore,
                wonWordsStore: wonWordsStore,
                syncStatusStore: syncStatusStore
            )
            scheduleCloudSync(
                authStore: authStore,
                pawPointsStore: pawPointsStore,
                wonWordsStore: wonWordsStore,
                syncStatusStore: syncStatusStore
            )
        } else {
            syncTask?.cancel()
            syncStatusStore.reset()
        }
    }

    func handleLocalDataChange(
        authStore: AuthStore,
        pawPointsStore: PawPointsStore,
        wonWordsStore: WonWordsStore,
        syncStatusStore: SyncStatusStore
    ) {
        guard !isApplyingRemoteSnapshot else { return }
        scheduleCloudSync(
            authStore: authStore,
            pawPointsStore: pawPointsStore,
            wonWordsStore: wonWordsStore,
            syncStatusStore: syncStatusStore
        )
    }

    private func refreshFromCloud(
        authStore: AuthStore,
        pawPointsStore: PawPointsStore,
        wonWordsStore: WonWordsStore,
        syncStatusStore: SyncStatusStore
    ) {
        guard let userId = authStore.currentUserId, let token = authStore.accessToken else { return }

        syncStatusStore.state = .syncing

        Task {
            do {
                let snapshot = try await playerDataService.fetchSnapshot(userId: userId, accessToken: token)
                applySnapshot(snapshot, pawPointsStore: pawPointsStore, wonWordsStore: wonWordsStore)
                syncStatusStore.markSynced()
            } catch {
                if SyncErrorClassifier.isLikelyOffline(error) {
                    syncStatusStore.markOffline(error: error)
                } else {
                    syncStatusStore.markFailed(error)
                }
            }
        }
    }

    private func scheduleCloudSync(
        authStore: AuthStore,
        pawPointsStore: PawPointsStore,
        wonWordsStore: WonWordsStore,
        syncStatusStore: SyncStatusStore
    ) {
        guard authStore.isAuthenticated else { return }
        guard let userId = authStore.currentUserId, let token = authStore.accessToken else { return }

        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            syncStatusStore.state = .syncing

            do {
                try await playerDataService.syncAll(
                    userId: userId,
                    accessToken: token,
                    pawPoints: pawPointsStore.balance,
                    wonWords: wonWordsStore.wonWords
                )
                let snapshot = try await playerDataService.fetchSnapshot(userId: userId, accessToken: token)
                applySnapshot(snapshot, pawPointsStore: pawPointsStore, wonWordsStore: wonWordsStore)
                syncStatusStore.markSynced()
            } catch {
                if SyncErrorClassifier.isLikelyOffline(error) {
                    syncStatusStore.markOffline(error: error)
                } else {
                    syncStatusStore.markFailed(error)
                }
            }
        }
    }

    private func applySnapshot(_ snapshot: PlayerSnapshot, pawPointsStore: PawPointsStore, wonWordsStore: WonWordsStore) {
        isApplyingRemoteSnapshot = true
        defer { isApplyingRemoteSnapshot = false }

        if let remotePoints = snapshot.pawPoints {
            pawPointsStore.setBalance(remotePoints)
        }
        wonWordsStore.replaceAll(snapshot.wonWords)
    }
}
