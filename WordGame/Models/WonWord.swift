import Foundation

struct WonWord: Codable, Identifiable, Equatable {
    let id: UUID
    let word: String
    let tries: Int
    let maxAttempts: Int
    let date: Date
    let sticker: Sticker
    let pawPoints: Int?
    let category: String?
    let difficulty: Int?
    let wordLength: Int?

    init(
        word: String,
        tries: Int,
        maxAttempts: Int,
        date: Date = Date(),
        sticker: Sticker,
        pawPoints: Int? = nil,
        category: String? = nil,
        difficulty: Int? = nil,
        wordLength: Int? = nil
    ) {
        self.id = UUID()
        self.word = word
        self.tries = tries
        self.maxAttempts = maxAttempts
        self.date = date
        self.sticker = sticker
        self.pawPoints = pawPoints
        self.category = category
        self.difficulty = difficulty
        self.wordLength = wordLength
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var triesDisplay: String {
        "\(tries)/\(maxAttempts)"
    }
}
