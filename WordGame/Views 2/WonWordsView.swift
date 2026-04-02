import SwiftUI

struct WonWordsView: View {
    @EnvironmentObject var store: WonWordsStore
    @State private var showClearAlert = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Clear All header
                if !store.wonWords.isEmpty {
                    HStack {
                        Spacer()
                        Button("Clear All", role: .destructive) {
                            showClearAlert = true
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                if store.wonWords.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    List {
                        ForEach(store.wonWords) { w in
                            NavigationLink {
                                WonWordDetailView(wonWord: w)
                            } label: {
                                row(w)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .alert("Clear All Wins?", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) { store.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your won words and stickers.")
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 48))
            Text("No wins yet!")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Start a game and guess the word\nto earn stickers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
    }

    private func row(_ w: WonWord) -> some View {
        HStack(spacing: 12) {
            Text(w.sticker.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(w.word.uppercased())
                    .font(.headline.monospaced())
                Text(w.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(w.triesDisplay)
                    .font(.subheadline.bold())
                Text(w.sticker.rarity.displayName)
                    .font(.caption2)
                    .foregroundStyle(rarityColor(w.sticker.rarity))
            }
        }
        .padding(.vertical, 4)
    }

    private func rarityColor(_ r: StickerRarity) -> Color {
        switch r {
        case .common: return .orange
        case .rare:   return .blue
        case .epic:   return .purple
        }
    }
}
