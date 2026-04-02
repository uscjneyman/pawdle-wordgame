import SwiftUI

/// Shared top navigation bar: ? (left) | sync status (center) | profile (right)
struct TopNavBar: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var syncStatusStore: SyncStatusStore

    var onInstructions: () -> Void
    var onProfile: () -> Void

    var body: some View {
        HStack {
            Button(action: onInstructions) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }

            Spacer()

            if authStore.isAuthenticated {
                HStack(spacing: 5) {
                    Image(systemName: syncStatusStore.state.icon)
                    Text(syncStatusStore.state.label)
                        .lineLimit(1)
                }
                .font(.caption2)
                .foregroundStyle(syncStatusStore.state.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(syncStatusStore.state.color.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            Button(action: onProfile) {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
