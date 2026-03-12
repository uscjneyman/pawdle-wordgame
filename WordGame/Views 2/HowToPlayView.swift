import SwiftUI
import Combine

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    private let pageCount = 5

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        WelcomePage().tag(0)
                        SetupPage().tag(1)
                        GameplayPage().tag(2)
                        ColorsPage().tag(3)
                        RewardsPage().tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentPage)

                    // Custom page indicator + navigation
                    VStack(spacing: 16) {
                        // Dots
                        HStack(spacing: 8) {
                            ForEach(0..<pageCount, id: \.self) { i in
                                Circle()
                                    .fill(i == currentPage ? Theme.accent : Theme.tileBorder)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(i == currentPage ? 1.3 : 1.0)
                                    .animation(.spring(response: 0.3), value: currentPage)
                            }
                        }

                        // Button row
                        HStack {
                            if currentPage > 0 {
                                Button { withAnimation { currentPage -= 1 } } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.accent)
                                }
                            }

                            Spacer()

                            if currentPage < pageCount - 1 {
                                Button { withAnimation { currentPage += 1 } } label: {
                                    HStack(spacing: 4) {
                                        Text("Next")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Theme.accent)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                            } else {
                                Button { dismiss() } label: {
                                    Text("Let's Play!")
                                        .font(.subheadline.weight(.bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Theme.accent)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🐾")
                .font(.system(size: 80))
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: appeared)

            Text("Welcome to Paw-dle!")
                .font(.title.bold())
                .foregroundStyle(Theme.accent)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

            Text("A word-guessing game where you\nuncover the secret word, one letter at a time.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)

            Text("Swipe to learn how →")
                .font(.caption)
                .foregroundStyle(Theme.accent.opacity(0.7))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.8), value: appeared)

            Spacer()
        }
        .padding(24)
        .onAppear { appeared = true }
    }
}

// MARK: - Page 2: Setup

private struct SetupPage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("⚙️")
                .font(.system(size: 56))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appeared)

            Text("Choose Your Challenge")
                .font(.title2.bold())
                .foregroundStyle(Theme.accent)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appeared)

            VStack(alignment: .leading, spacing: 16) {
                stepRow(icon: "square.grid.2x2",
                        title: "Category",
                        detail: "Pick Animals, Food, Nature, and more — or Random!",
                        delay: 0.3)

                stepRow(icon: "textformat.size",
                        title: "Word Length",
                        detail: "Pick 4 to 8 letters — longer words are trickier!",
                        delay: 0.45)

                stepRow(icon: "speedometer",
                        title: "Difficulty",
                        detail: "Easy uses everyday words. Hard gets obscure and disables reveals.",
                        delay: 0.6)

                stepRow(icon: "number",
                        title: "Attempts",
                        detail: "You get word-length + 1 guesses to find it.",
                        delay: 0.75)
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(24)
        .onAppear { appeared = true }
    }

    private func stepRow(icon: String, title: String, detail: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -30)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
}

// MARK: - Page 3: Gameplay

private struct GameplayPage: View {
    @State private var appeared = false
    @State private var typedCount = 0
    private let word = Array("CRANE")
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("⌨️")
                .font(.system(size: 56))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appeared)

            Text("Type & Submit")
                .font(.title2.bold())
                .foregroundStyle(Theme.accent)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appeared)

            // Animated tiles showing letters appearing
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    let filled = i < typedCount
                    Text(filled ? String(word[i]) : "")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .frame(width: 48, height: 48)
                        .background(Theme.tileEmpty)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(filled ? Theme.accent : Theme.tileBorder, lineWidth: filled ? 2 : 1)
                        )
                        .scaleEffect(filled ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25), value: filled)
                }
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                bulletRow("You'll see a riddle clue at the top — use it!", delay: 0.4)
                bulletRow("Type letters with the keyboard, tap \u{232B} to delete.", delay: 0.55)
                bulletRow("Press \u{21B5} Enter to submit your guess.", delay: 0.7)
                bulletRow("Tap \u{1F43E} Reveal to uncover a letter (costs 1 paw point).", delay: 0.85)
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(24)
        .onAppear { appeared = true }
        .onReceive(timer) { _ in
            if typedCount < 5 { typedCount += 1 }
        }
    }

    private func bulletRow(_ text: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundStyle(Theme.accent)
                .font(.body.bold())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -30)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
}

// MARK: - Page 4: Colors

private struct ColorsPage: View {
    @State private var appeared = false
    @State private var revealStep = 0
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    // Example: secret is "CRANE", guess is "CLEAR"
    // C=correct, L=absent, E=present, A=present, R=present
    private let letters  = ["C", "L", "E", "A", "R"]
    private let states: [LetterState] = [.correct, .absent, .present, .present, .present]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🎨")
                .font(.system(size: 56))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appeared)

            Text("Read the Colors")
                .font(.title2.bold())
                .foregroundStyle(Theme.accent)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appeared)

            // Animated reveal of colored tiles
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    let revealed = i < revealStep
                    Text(letters[i])
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .frame(width: 48, height: 48)
                        .background(revealed ? Theme.color(for: states[i]) : Theme.tileEmpty)
                        .foregroundColor(revealed ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(revealed ? Theme.color(for: states[i]) : Theme.tileBorder,
                                        lineWidth: revealed ? 2 : 1)
                        )
                        .rotation3DEffect(
                            .degrees(revealed ? 0 : -90),
                            axis: (x: 1, y: 0, z: 0)
                        )
                        .animation(
                            .easeInOut(duration: 0.4).delay(Double(i) * 0.15),
                            value: revealStep
                        )
                }
            }
            .padding(.vertical, 8)

            // Legend
            VStack(alignment: .leading, spacing: 14) {
                colorRow(color: Theme.correct, emoji: "🟩",
                         text: "Green — right letter, right spot",
                         delay: 0.4)
                colorRow(color: Theme.present, emoji: "🟨",
                         text: "Yellow — right letter, wrong spot",
                         delay: 0.55)
                colorRow(color: Theme.absent, emoji: "⬜️",
                         text: "Gray — letter not in the word",
                         delay: 0.7)
            }
            .padding(.horizontal, 8)

            Text("The keyboard also updates to show which\nletters you've already tried.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.9), value: appeared)

            Spacer()
        }
        .padding(24)
        .onAppear {
            appeared = true
            revealStep = 0
        }
        .onReceive(timer) { _ in
            if appeared && revealStep < 5 { revealStep += 1 }
        }
    }

    private func colorRow(color: Color, emoji: String, text: String, delay: Double) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -30)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
}

// MARK: - Page 5: Rewards

private struct RewardsPage: View {
    @State private var appeared = false
    @State private var stickerBounce = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🎁")
                .font(.system(size: 56))
                .scaleEffect(stickerBounce ? 1.15 : 1.0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.4)
                        .repeatForever(autoreverses: true),
                    value: stickerBounce
                )
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.1), value: appeared)

            Text("Earn Stickers!")
                .font(.title2.bold())
                .foregroundStyle(Theme.accent)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.2), value: appeared)

            Text("Win games to earn paw points and stickers.\nFewer guesses = more points = rarer stickers!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.35), value: appeared)

            VStack(spacing: 16) {
                stickerRow(emoji: "🐾", label: "Paw Points",
                           detail: "Earn 1–5 per win. Spend to reveal letters.", delay: 0.5)
                stickerRow(emoji: "🏆", label: "Epic",
                           detail: "Guess in 1–2 tries", delay: 0.65)
                stickerRow(emoji: "💎", label: "Rare",
                           detail: "Guess in 3–4 tries", delay: 0.8)
                stickerRow(emoji: "⭐️", label: "Common",
                           detail: "Guess in 5+ tries", delay: 0.95)
            }
            .padding(.horizontal, 8)

            Text("You start with 2 paw points. Spend wisely!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(1.1), value: appeared)

            Spacer()
        }
        .padding(24)
        .onAppear {
            appeared = true
            stickerBounce = true
        }
    }

    private func stickerRow(emoji: String, label: String, detail: String, delay: Double) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.largeTitle)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Theme.tileEmpty)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
}
