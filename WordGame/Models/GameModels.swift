import Foundation

// MARK: - Letter State

enum LetterState: String, Codable, Comparable {
    case unknown
    case absent
    case present
    case correct

    /// Precedence for keyboard coloring: correct > present > absent > unknown
    private var precedence: Int {
        switch self {
        case .unknown: return 0
        case .absent:  return 1
        case .present: return 2
        case .correct: return 3
        }
    }

    static func < (lhs: LetterState, rhs: LetterState) -> Bool {
        lhs.precedence < rhs.precedence
    }
}

// MARK: - Letter Result

struct LetterResult: Codable, Identifiable, Equatable {
    let id: UUID
    let letter: String
    let state: LetterState

    init(letter: String, state: LetterState) {
        self.id = UUID()
        self.letter = letter
        self.state = state
    }

    enum CodingKeys: String, CodingKey {
        case id, letter, state
    }
}

// MARK: - Guess

struct Guess: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let results: [LetterResult]

    init(text: String, results: [LetterResult]) {
        self.id = UUID()
        self.text = text
        self.results = results
    }

    enum CodingKeys: String, CodingKey {
        case id, text, results
    }
}

// MARK: - Game Status

enum GameStatus: String, Codable {
    case playing
    case won
    case lost
}

// MARK: - Game Session

struct GameSession {
    let id: UUID
    let secretWord: String
    var guesses: [Guess]
    var currentGuess: String
    var revealedPositions: Set<Int> = []
    let wordLength: Int
    let maxAttempts: Int
    var status: GameStatus
    let startedAt: Date
    var finishedAt: Date?
    var definition: String?

    init(secretWord: String, wordLength: Int) {
        self.id = UUID()
        self.secretWord = secretWord.lowercased()
        self.guesses = []
        self.currentGuess = ""
        self.wordLength = wordLength
        self.maxAttempts = wordLength + 1
        self.status = .playing
        self.startedAt = Date()
    }
}
