import SwiftUI
import Combine
import UIKit

@MainActor
class GameViewModel: ObservableObject {

    // MARK: - Navigation

    @Published var isGameActive = false
    @Published var isGameOver = false

    // MARK: - Game state

    @Published var session: GameSession?
    @Published var keyboardState: [String: LetterState] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var riddleText: String?
    @Published var showRiddlePopup = false
    @Published var hintDefinition: String?
    @Published var definitionRevealed = false
    @Published var revealedRows: Set<Int> = []
    @Published var shakeCurrentRow = false
    @Published var pawPointsEarned: Int = 0

    // MARK: - Settings

    @Published var wordLength = 5
    @Published var difficulty = 1
    @Published var category: WordCategory = .random

    // MARK: - Dependencies

    private let dictionaryService = DictionaryService()
    private let riddleService = RiddleService()
    var pawPointsStore: PawPointsStore?
    var wonWordsStore: WonWordsStore?

    // MARK: - Computed helpers

    var currentAttempt: Int { session?.guesses.count ?? 0 }
    var maxAttempts: Int    { session?.maxAttempts ?? 6 }

    var canUsePawReveal: Bool {
        guard let session, session.status == .playing else { return false }
        guard difficulty < 3 else { return false }
        guard (pawPointsStore?.balance ?? 0) >= 1 else { return false }
        return session.revealedPositions.count < session.wordLength
    }

    var canUseDefinitionHint: Bool {
        guard let session, session.status == .playing else { return false }
        guard !definitionRevealed else { return false }
        return (pawPointsStore?.balance ?? 0) >= 2
    }

    // MARK: - Actions

    func startNewGame() {
        guard !isLoading else { return }
        // Reset transient UI/game state before loading next riddle.
        isLoading = true
        errorMessage = nil
        riddleText = nil
        showRiddlePopup = false
        hintDefinition = nil
        definitionRevealed = false
        keyboardState = [:]
        revealedRows = []
        pawPointsEarned = 0

        Task {
            // Avoid serving already-solved words for the same configuration.
            let solvedWords = solvedWordsForCurrentConfiguration()

            // 1️⃣ Try the riddle API — its answer becomes the secret word
            print("[GameVM] Fetching riddle with category=\(category.rawValue), difficulty=\(difficulty), wordLength=\(wordLength)")
            let poolTotal = await riddleService.fetchPoolTotal(
                wordLength: wordLength,
                difficulty: difficulty,
                category: category
            )

            if let poolTotal, poolTotal > 0, solvedWords.count >= poolTotal {
                isLoading = false
                errorMessage = completionMessage(total: poolTotal)
                return
            }

            if let result = await riddleService.fetchRiddle(
                wordLength: wordLength,
                difficulty: difficulty,
                category: category,
                excluding: solvedWords
            ) {
                let word = result.answer
                print("[GameVM] ✅ Using riddle answer as word: \(word)")

                // The riddle API answer is the secret word for the current session.
                session = GameSession(secretWord: word, wordLength: wordLength)
                riddleText = "🧩 \(result.riddle)"
                isLoading = false
                isGameOver = false
                isGameActive = true
                showRiddlePopup = true
                return
            }

            isLoading = false
            if let poolTotal, poolTotal > 0 {
                errorMessage = completionMessage(total: poolTotal)
            } else {
                errorMessage = "Could not load a riddle for this setup. Please try again."
            }
        }
    }

    func typeLetter(_ letter: String) {
        guard var s = session, s.status == .playing else { return }
        let l = letter.lowercased()
        guard l.count == 1, l.first?.isLetter == true else { return }
        guard s.currentGuess.count < s.wordLength else { return }
        s.currentGuess.append(l)
        session = s
    }

    func backspace() {
        guard var s = session, s.status == .playing else { return }
        guard !s.currentGuess.isEmpty else { return }
        s.currentGuess.removeLast()
        session = s
    }

    func submitGuess() {
        guard var s = session, s.status == .playing else { return }
        let guess = s.currentGuess.lowercased()

        guard guess.count == s.wordLength else { triggerShake(); return }
        guard guess.allSatisfy({ $0.isLetter }) else { triggerShake(); return }

        let results = evaluateGuess(guess, secret: s.secretWord)
        // Save the submitted row and clear the input buffer.
        s.guesses.append(Guess(text: guess, results: results))
        s.currentGuess = ""

        updateKeyboard(with: results)

        // Check win / lose
        if guess == s.secretWord {
            s.status = .won
            s.finishedAt = Date()
        } else if s.guesses.count >= s.maxAttempts {
            s.status = .lost
            s.finishedAt = Date()
        }

        session = s

        // Staggered tile reveal animation
        let rowIndex = s.guesses.count - 1
        withAnimation(.easeInOut(duration: 0.3)) {
            _ = revealedRows.insert(rowIndex)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if s.status != .playing {
            handleGameEnd()
        }
    }

    func usePawReveal() {
        guard var s = session, canUsePawReveal else { return }
        guard pawPointsStore?.spend(1) == true else { return }

        let all = Set(0..<s.wordLength)
        let unrevealed = all.subtracting(s.revealedPositions)
        guard let pos = unrevealed.randomElement() else { return }

        s.revealedPositions.insert(pos)
        session = s

        let letter = String(Array(s.secretWord)[pos]).uppercased()
        let current = keyboardState[letter] ?? .unknown
        if LetterState.correct > current { keyboardState[letter] = .correct }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Spend 2 paw points to reveal the dictionary definition as a hint.
    func revealDefinitionHint() {
        guard !definitionRevealed else { return }
        guard let session, session.status == .playing else { return }
        guard pawPointsStore?.spend(2) == true else { return }

        definitionRevealed = true

        Task {
            // Pull definition lazily so we only pay the network cost when requested.
            let definition = await dictionaryService.fetchDefinition(for: session.secretWord)
            hintDefinition = definition
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func playAgain() {
        isGameOver = false
        isGameActive = false
        session = nil
        riddleText = nil
        showRiddlePopup = false
        hintDefinition = nil
        definitionRevealed = false
        keyboardState = [:]
        revealedRows = []
        errorMessage = nil
        pawPointsEarned = 0
    }

    // MARK: - Share result (Wordle-style colored squares)

    func shareText() -> String {
        guard let session else { return "" }
        let score = session.status == .won
            ? "\(session.guesses.count)/\(session.maxAttempts)"
            : "X/\(session.maxAttempts)"

        let catLabel = category != .random ? " \(category.emoji)" : ""
        var lines = ["Paw-dle\(catLabel) \(score)"]

        if session.status == .won {
            lines[0] += " (+\(Self.pawPointsForWin(guesses: session.guesses.count))\u{1F43E})"
        }

        lines.append("")
        for guess in session.guesses {
            let row = guess.results.map { r -> String in
                switch r.state {
                case .correct: return "🟩"
                case .present: return "🟨"
                case .absent, .unknown: return "⬜"
                }
            }.joined()
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Scoring

    static func pawPointsForWin(guesses: Int) -> Int {
        switch guesses {
        case 1:  return 5
        case 2:  return 4
        case 3:  return 3
        case 4:  return 2
        default: return 1
        }
    }

    // MARK: - Wordle evaluation (classic two-pass with duplicate handling)

    func evaluateGuess(_ guess: String, secret: String) -> [LetterResult] {
        let g = Array(guess)
        let s = Array(secret)
        let n = g.count
        var states = [LetterState](repeating: .absent, count: n)

        // Build remaining-letter frequency from secret
        var remaining: [Character: Int] = [:]
        for c in s { remaining[c, default: 0] += 1 }

        // Pass 1 – exact matches (green)
        for i in 0..<n where g[i] == s[i] {
            states[i] = .correct
            remaining[g[i], default: 0] -= 1
        }

        // Pass 2 – present but wrong position (yellow)
        for i in 0..<n {
            guard states[i] != .correct else { continue }
            if remaining[g[i], default: 0] > 0 {
                states[i] = .present
                remaining[g[i]]! -= 1
            }
        }

        return (0..<n).map { LetterResult(letter: String(g[$0]), state: states[$0]) }
    }

    // MARK: - Private helpers

    private func handleGameEnd() {
        Task {
            let status = session?.status

            // Let the last tile animation finish before transitioning screens.
            try? await Task.sleep(nanoseconds: 800_000_000)

            // Show dictionary definition on the end screen
            if session?.definition == nil {
                if let hint = hintDefinition {
                    session?.definition = hint
                } else {
                    let def = await dictionaryService.fetchDefinition(for: session?.secretWord ?? "")
                    if def != "No definition found." {
                        session?.definition = def
                    }
                }
            }

            if status == .won {
                let pts = Self.pawPointsForWin(guesses: session?.guesses.count ?? 6)
                pawPointsEarned = pts
                pawPointsStore?.earn(pts)
            }

            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(status == .won ? .success : .error)

            if status == .won {
                SoundManager.shared.playVictory()
            } else {
                SoundManager.shared.playSadTrombone()
            }

            isGameOver = true
        }
    }

    private func updateKeyboard(with results: [LetterResult]) {
        for r in results {
            let key = r.letter.uppercased()
            let current = keyboardState[key] ?? .unknown
            if r.state > current { keyboardState[key] = r.state }
        }
    }

    private func triggerShake() {
        shakeCurrentRow = true
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            shakeCurrentRow = false
        }
    }

    private func solvedWordsForCurrentConfiguration() -> Set<String> {
        guard let store = wonWordsStore else { return [] }

        let categoryMatch: (WonWord) -> Bool = { record in
            guard let savedCategory = record.category else { return false }
            if self.category == .random {
                return ["animals", "mystery", "science"].contains(savedCategory)
            }
            return savedCategory == self.category.rawValue
        }

        return Set(
            store.wonWords
                .filter { $0.wordLength == wordLength }
                .filter { $0.difficulty == difficulty }
                .filter(categoryMatch)
                .map { $0.word.lowercased() }
        )
    }

    private func completionMessage(total: Int) -> String {
        let difficultyLabel: String
        switch difficulty {
        case 1: difficultyLabel = "Easy"
        case 2: difficultyLabel = "Medium"
        default: difficultyLabel = "Hard"
        }

        let categoryLabel = category.displayName
        return "You solved all \(total) riddles for \(categoryLabel), \(wordLength)-letter, \(difficultyLabel). Pick a different setup to keep playing."
    }
}
