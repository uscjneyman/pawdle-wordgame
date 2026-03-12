import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var wonWordsStore: WonWordsStore

    private let keyRows: [[String]] = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["ENTER","Z","X","C","V","B","N","M","⌫"]
    ]

    var body: some View {
        GeometryReader { geo in
            // Compute board dimensions from current word settings and screen width.
            let wl = viewModel.session?.wordLength ?? 5
            let ma = viewModel.session?.maxAttempts ?? 6
            let tile = tileSize(wordLength: wl, screenWidth: geo.size.width)

            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 4) {
                    // Header
                    header

                    // Revealed letters bar
                    if viewModel.difficulty < 3,
                       let session = viewModel.session,
                       session.status == .playing {
                        revealBar(session: session)
                    }

                    Spacer(minLength: 2)

                    // Word grid
                    grid(wordLength: wl, maxAttempts: ma, tileSize: tile)

                    Spacer(minLength: 2)

                    // Paw reveal / hints
                    hintSection

                    Spacer(minLength: 2)

                    // Keyboard
                    keyboard
                        .padding(.bottom, 6)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $viewModel.isGameOver) {
            EndView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showRiddlePopup) {
            riddlePopup
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                viewModel.playAgain()
            } label: {
                Image(systemName: "house.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                    .padding(8)
                    .background(Theme.tileEmpty)
                    .clipShape(Circle())
            }

            HStack(spacing: 6) {
                Text("Paw-dle")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.accent)

                if viewModel.category != .random {
                    Text(viewModel.category.emoji)
                        .font(.title3)
                }
            }

            Spacer()

            // Show-riddle button
            if viewModel.riddleText != nil {
                Button { viewModel.showRiddlePopup = true } label: {
                    Image(systemName: "lightbulb.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                }
            }

            if let s = viewModel.session, s.status == .playing {
                Text("Guess \(s.guesses.count + 1)/\(s.maxAttempts)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Grid

    private func grid(wordLength: Int, maxAttempts: Int, tileSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<maxAttempts, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<wordLength, id: \.self) { col in
                        tile(row: row, col: col, size: tileSize)
                    }
                }
                .modifier(ShakeEffect(shaking: row == viewModel.currentAttempt && viewModel.shakeCurrentRow))
            }
        }
        .padding(.horizontal, 8)
    }

    private func tile(row: Int, col: Int, size: CGFloat) -> some View {
        // Guard against invalid geometry values during transitional layout passes.
        let safeSize = size.isFinite && size > 0 ? size : 1
        let guesses = viewModel.session?.guesses ?? []
        let current = viewModel.session?.currentGuess ?? ""
        let curRow  = guesses.count

        let letter: String
        let state: LetterState
        let revealed: Bool

        if row < guesses.count {
            // Locked row: render evaluated result.
            let g = guesses[row]
            letter   = col < g.results.count ? g.results[col].letter.uppercased() : ""
            state    = col < g.results.count ? g.results[col].state : .unknown
            revealed = viewModel.revealedRows.contains(row)
        } else if row == curRow {
            // Active row: show live typing state.
            let chars = Array(current)
            letter   = col < chars.count ? String(chars[col]).uppercased() : ""
            state    = .unknown
            revealed = false
        } else {
            // Future row: empty placeholder tile.
            letter   = ""
            state    = .unknown
            revealed = false
        }

        let bg    = revealed ? Theme.color(for: state) : Theme.tileEmpty
        let fg    = revealed ? Theme.textColor(for: state) : Color.primary
        let border = revealed ? Theme.color(for: state)
                              : (letter.isEmpty ? Theme.tileBorder : Theme.accent.opacity(0.5))

        return Text(letter)
            .font(.system(size: safeSize * 0.48, weight: .bold, design: .rounded))
            .frame(width: safeSize, height: safeSize)
            .background(bg)
            .foregroundColor(fg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(border, lineWidth: revealed ? 2 : 1)
            )
            .scaleEffect(revealed && row == viewModel.currentAttempt - 1 ? 1.0 : 1.0)
            .animation(
                .easeInOut(duration: 0.25).delay(Double(col) * 0.12),
                value: revealed
            )
    }

    private func tileSize(wordLength: Int, screenWidth: CGFloat) -> CGFloat {
        guard wordLength > 0, screenWidth.isFinite else { return 44 }
        // Leave horizontal padding + spacing, then cap to keep tiles readable on tablets.
        let spacing = CGFloat(wordLength - 1) * 4 + 16
        let available = screenWidth - spacing
        let rawSize = min(available / CGFloat(wordLength), 56)
        return max(24, rawSize)
    }

    // MARK: - Riddle Popup

    private var riddlePopup: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("\u{1F9E9}")
                .font(.system(size: 48))

            Text("Your Riddle")
                .font(.title2.bold())
                .foregroundStyle(Theme.accent)

            Text(viewModel.riddleText ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button { viewModel.showRiddlePopup = false } label: {
                Text("Got it!")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.vertical, 32)
        .presentationDetents([.medium])
    }

    // MARK: - Reveal Bar

    private func revealBar(session: GameSession) -> some View {
        let chars = Array(session.secretWord)
        return HStack(spacing: 6) {
            ForEach(0..<session.wordLength, id: \.self) { i in
                if session.revealedPositions.contains(i), i < chars.count {
                    Text(String(chars[i]).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28, height: 32)
                        .background(Theme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("_")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.quaternary)
                        .frame(width: 28, height: 32)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Hints (definition + letter reveal)

    @ViewBuilder
    private var hintSection: some View {
        if let session = viewModel.session, session.status == .playing {
            VStack(spacing: 8) {
                // Dictionary definition hint
                if viewModel.definitionRevealed, let def = viewModel.hintDefinition {
                    HStack(alignment: .top, spacing: 6) {
                        Text("\u{1F4D6}")
                        Text(def)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                } else if viewModel.definitionRevealed {
                    ProgressView()
                        .padding(.vertical, 4)
                } else {
                    Button { viewModel.revealDefinitionHint() } label: {
                        HStack(spacing: 6) {
                            Text("\u{1F4D6}")
                            Text("Get Definition Hint")
                                .font(.caption.bold())
                            Text("(2 \u{1F43E})")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(viewModel.canUseDefinitionHint ? Theme.accent.opacity(0.12) : Theme.tileEmpty.opacity(0.5))
                        .foregroundStyle(viewModel.canUseDefinitionHint ? Theme.accent : .secondary)
                        .clipShape(Capsule())
                    }
                    .disabled(!viewModel.canUseDefinitionHint)
                }

                // Letter reveal
                if viewModel.difficulty >= 3 {
                    Text("Hard mode \u{2014} no letter reveals")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Button { viewModel.usePawReveal() } label: {
                        HStack(spacing: 6) {
                            Text("\u{1F43E}")
                            Text("Reveal a Letter")
                                .font(.caption.bold())
                            Text("(\(viewModel.pawPointsStore?.balance ?? 0) \u{1F43E} left)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(viewModel.canUsePawReveal ? Theme.accent.opacity(0.12) : Theme.tileEmpty.opacity(0.5))
                        .foregroundStyle(viewModel.canUsePawReveal ? Theme.accent : .secondary)
                        .clipShape(Capsule())
                    }
                    .disabled(!viewModel.canUsePawReveal)
                }
            }
        }
    }

    // MARK: - Keyboard

    private var keyboard: some View {
        VStack(spacing: 6) {
            ForEach(keyRows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private func keyButton(_ key: String) -> some View {
        // Special keys get custom sizing and labels, letters use state coloring.
        let special = key == "ENTER" || key == "⌫"
        let st = viewModel.keyboardState[key] ?? .unknown
        let bg: Color = special ? Theme.keyBg : Theme.color(for: st)
        let fg: Color = (st == .unknown || special) ? .primary : .white

        return Button {
            switch key {
            case "ENTER": viewModel.submitGuess()
            case "⌫":     viewModel.backspace()
            default:       viewModel.typeLetter(key)
            }
        } label: {
            Text(key == "ENTER" ? "↵" : key)
                .font(.system(size: special ? 16 : 14, weight: .semibold, design: .rounded))
                .frame(minWidth: special ? 44 : 30, minHeight: 44)
                .background(bg)
                .foregroundColor(fg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

// MARK: - Shake animation modifier

struct ShakeEffect: ViewModifier {
    let shaking: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: shaking ? -6 : 0)
            .animation(
                shaking
                    ? .default.repeatCount(3, autoreverses: true).speed(6)
                    : .default,
                value: shaking
            )
    }
}
