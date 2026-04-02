import SwiftUI

/// A shareable celebration card for a won word.
struct ShowOffCardView: View {
    let username: String
    let wonWord: WonWord

    var body: some View {
        VStack(spacing: 16) {
            // Confetti header
            HStack(spacing: 4) {
                Text("🎉")
                Text("🎊")
                Text("🥳")
                Text("🎉")
            }
            .font(.title)

            Text("\(username) just solved a word on Paw-dle!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.accent)

            // The word
            Text(wonWord.word.uppercased())
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .tracking(4)
                .foregroundStyle(.primary)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text(wonWord.triesDisplay)
                        .font(.title3.bold())
                    Text("Tries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let pts = wonWord.pawPoints {
                    VStack(spacing: 2) {
                        Text("+\(pts)")
                            .font(.title3.bold())
                        Text("🐾 Earned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Sticker badge
            VStack(spacing: 4) {
                Text(wonWord.sticker.emoji)
                    .font(.system(size: 48))
                Text(wonWord.sticker.name)
                    .font(.subheadline.bold())
                Text(wonWord.sticker.rarity.displayName)
                    .font(.caption2)
                    .foregroundStyle(rarityColor(wonWord.sticker.rarity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(rarityColor(wonWord.sticker.rarity).opacity(0.12))
                    .clipShape(Capsule())
            }

            Text("🐾 Paw-dle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Theme.accent.opacity(0.15), radius: 12, y: 4)
    }

    private func rarityColor(_ r: StickerRarity) -> Color {
        switch r {
        case .common: return .orange
        case .rare:   return .blue
        case .epic:   return .purple
        }
    }
}

// MARK: - Snapshot renderer for sharing

extension ShowOffCardView {
    /// Renders this card to a UIImage for sharing via the system share sheet.
    @MainActor
    func renderImage() -> UIImage {
        let renderer = ImageRenderer(content: self.padding(16).background(Color.white))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}
