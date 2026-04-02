import Foundation

struct CommunityPost: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let username: String
    let word: String
    let tries: Int
    let maxAttempts: Int
    let stickerEmoji: String
    let stickerName: String
    let stickerRarity: String
    let pawPointsEarned: Int?
    let category: String?
    let difficulty: Int?
    let wordLength: Int?
    let createdAt: Date

    var triesDisplay: String { "\(tries)/\(maxAttempts)" }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: createdAt)
    }

    var rarityEnum: StickerRarity {
        StickerRarity(rawValue: stickerRarity) ?? .common
    }
}
