import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var communityStore: CommunityStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if communityStore.isLoading && communityStore.posts.isEmpty {
                ProgressView("Loading community posts…")
            } else if communityStore.posts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(communityStore.posts) { post in
                            CommunityPostCard(post: post)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await communityStore.refresh()
                }
            }
        }
        .task {
            await communityStore.refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🌍")
                .font(.system(size: 48))
            Text("No posts yet!")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Be the first to show off a win\nand publish to the community.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
    }
}

// MARK: - Individual post card in the feed

private struct CommunityPostCard: View {
    let post: CommunityPost

    var body: some View {
        VStack(spacing: 12) {
            // Confetti row
            HStack(spacing: 4) {
                Text("🎉")
                Text("🎊")
                Text("🥳")
                Text("🎉")
            }
            .font(.callout)

            Text("\(post.username) just solved a word on Paw-dle!")
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.accent)

            Text(post.word.uppercased())
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .tracking(3)

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(post.triesDisplay)
                        .font(.subheadline.bold())
                    Text("Tries")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let pts = post.pawPointsEarned {
                    VStack(spacing: 2) {
                        Text("+\(pts)")
                            .font(.subheadline.bold())
                        Text("🐾 Earned")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Sticker
            HStack(spacing: 8) {
                Text(post.stickerEmoji)
                    .font(.title2)
                Text(post.stickerName)
                    .font(.caption.bold())
                Text(post.rarityEnum.displayName)
                    .font(.caption2)
                    .foregroundStyle(rarityColor(post.rarityEnum))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(rarityColor(post.rarityEnum).opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(post.formattedDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.tileEmpty)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.tileBorder, lineWidth: 1)
        )
    }

    private func rarityColor(_ r: StickerRarity) -> Color {
        switch r {
        case .common: return .orange
        case .rare:   return .blue
        case .epic:   return .purple
        }
    }
}
