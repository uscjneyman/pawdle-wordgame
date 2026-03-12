import Foundation

// MARK: - Sticker Rarity

enum StickerRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic

    var displayName: String { rawValue.capitalized }
}

// MARK: - Sticker

struct Sticker: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let rarity: StickerRarity

    /// Award a sticker based on how many tries it took.
    /// epic  = 1–2 tries, rare = 3–4, common = 5+
    static func award(for tries: Int) -> Sticker {
        let pool: [Sticker]
        if tries <= 2 {
            pool = epic
        } else if tries <= 4 {
            pool = rare
        } else {
            pool = common
        }
        return pool.randomElement()!
    }

    // --- Sticker pools ---

    static let common: [Sticker] = [
        Sticker(id: "bronze_star", name: "Bronze Star", emoji: "⭐️", rarity: .common),
        Sticker(id: "thumbs_up",   name: "Nice Try",   emoji: "👍", rarity: .common),
        Sticker(id: "clover",      name: "Lucky Find",  emoji: "🍀", rarity: .common),
    ]

    static let rare: [Sticker] = [
        Sticker(id: "silver_medal", name: "Sharp Mind",    emoji: "🏅", rarity: .rare),
        Sticker(id: "sparkles",     name: "Sparkle Brain", emoji: "✨", rarity: .rare),
        Sticker(id: "gem",          name: "Hidden Gem",    emoji: "💎", rarity: .rare),
    ]

    static let epic: [Sticker] = [
        Sticker(id: "gold_trophy", name: "Champion",     emoji: "🏆", rarity: .epic),
        Sticker(id: "rocket",      name: "Rocket Start", emoji: "🚀", rarity: .epic),
        Sticker(id: "crown",       name: "Word Royalty", emoji: "👑", rarity: .epic),
    ]
}
