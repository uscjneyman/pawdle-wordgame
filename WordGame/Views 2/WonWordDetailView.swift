import SwiftUI

struct WonWordDetailView: View {
    let wonWord: WonWord

    @State private var definition: String?
    @State private var isLoading = true
    @State private var showShowOff = false

    private let dictionaryService = DictionaryService()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 16)

                    // Sticker
                    Text(wonWord.sticker.emoji)
                        .font(.system(size: 72))

                    Text(wonWord.sticker.name)
                        .font(.title3.bold())

                    Text(wonWord.sticker.rarity.displayName)
                        .font(.caption)
                        .foregroundStyle(rarityColor(wonWord.sticker.rarity))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(rarityColor(wonWord.sticker.rarity).opacity(0.12))
                        .clipShape(Capsule())

                    Divider().padding(.horizontal, 40)

                    // Word
                    Text(wonWord.word.uppercased())
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(Theme.accent)

                    // Stats
                    HStack(spacing: 32) {
                        VStack {
                            Text(wonWord.triesDisplay)
                                .font(.title2.bold())
                            Text("Tries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack {
                            Text(wonWord.formattedDate)
                                .font(.subheadline.bold())
                            Text("Date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Definition
                    if isLoading {
                        ProgressView()
                            .padding(.top, 8)
                    } else if let definition {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Definition")
                                .font(.headline)
                            Text(definition)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Theme.tileEmpty)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                    }

                    // Show Off button
                    Button {
                        showShowOff = true
                    } label: {
                        Label("Show Off", systemImage: "star.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("Details")
        .sheet(isPresented: $showShowOff) {
            ShowOffMenuView(wonWord: wonWord)
        }
        .task {
            definition = await dictionaryService.fetchDefinition(for: wonWord.word)
            isLoading = false
        }
    }

    private func rarityColor(_ r: StickerRarity) -> Color {
        switch r {
        case .common: return .orange
        case .rare:   return .blue
        case .epic:   return .purple
        }
    }
}
