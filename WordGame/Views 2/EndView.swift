import SwiftUI
import UIKit

struct EndView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var wonWordsStore: WonWordsStore

    @State private var earnedSticker: Sticker?
    @State private var hasSaved = false
    @State private var animateSticker = false
    @State private var copied = false
    @State private var showShowOff = false
    @State private var savedRecord: WonWord?

    private var isWin: Bool { viewModel.session?.status == .won }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Win / Lose headline
                    Text(isWin ? "You Won!" : "Game Over")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(isWin ? Theme.correct : Theme.absent)

                    // Secret word
                    if let s = viewModel.session {
                        VStack(spacing: 8) {
                            Text("The word was")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(s.secretWord.uppercased())
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .tracking(4)
                                .foregroundStyle(Theme.accent)
                        }

                        // Definition
                        if let def = s.definition {
                            Text(def)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Theme.tileEmpty)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 24)
                        }

                        // Metadata
                        HStack(spacing: 32) {
                            VStack {
                                Text("\(s.guesses.count)/\(s.maxAttempts)")
                                    .font(.title2.bold())
                                Text("Tries")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if isWin {
                                VStack {
                                    Text("+\(viewModel.pawPointsEarned)")
                                        .font(.title2.bold())
                                    Text("\u{1F43E} Earned")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            VStack {
                                Text(Date().formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.title2.bold())
                                Text("Date")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Sticker (win only)
                    if let sticker = earnedSticker {
                        VStack(spacing: 8) {
                            Text(sticker.emoji)
                                .font(.system(size: 64))
                                .scaleEffect(animateSticker ? 1.0 : 0.3)
                                .opacity(animateSticker ? 1 : 0)

                            Text(sticker.name)
                                .font(.headline)

                            Text(sticker.rarity.displayName)
                                .font(.caption)
                                .foregroundStyle(rarityColor(sticker.rarity))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(rarityColor(sticker.rarity).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer(minLength: 20)

                    // Buttons
                    VStack(spacing: 12) {
                        if isWin, let record = savedRecord {
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
                        }

                        Button {
                            viewModel.goHome()
                        } label: {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.tileEmpty)
                            .foregroundColor(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            viewModel.playAgain()
                        } label: {
                            Text("Play Again")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accent)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showShowOff) {
            if let record = savedRecord {
                ShowOffMenuView(wonWord: record)
            }
        }
        .onAppear {
            guard !hasSaved else { return }

            if isWin, let s = viewModel.session {
                // Invariant: won word must be the exact answer returned by the riddle API for this session.
                guard viewModel.currentRiddleAnswer?.lowercased() == s.secretWord.lowercased() else {
                    hasSaved = true
                    return
                }

                let sticker = Sticker.award(for: s.guesses.count)
                earnedSticker = sticker

                let record = WonWord(
                    word: s.secretWord,
                    tries: s.guesses.count,
                    maxAttempts: s.maxAttempts,
                    sticker: sticker,
                    pawPoints: viewModel.pawPointsEarned,
                    category: viewModel.category.rawValue,
                    difficulty: viewModel.difficulty,
                    wordLength: s.wordLength
                )
                wonWordsStore.add(record)
                savedRecord = record
                hasSaved = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                animateSticker = true
            }
        }
    }

    private func rarityColor(_ rarity: StickerRarity) -> Color {
        switch rarity {
        case .common: return .orange
        case .rare:   return .blue
        case .epic:   return .purple
        }
    }
}
