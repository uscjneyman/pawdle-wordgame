import Foundation

enum FallbackWords {
    // ~110 curated words covering lengths 4–8
    static let words: [String] = [
        // 4-letter
        "bark", "bone", "cats", "dogs", "fish",
        "howl", "jump", "lick", "paws", "tail",
        "walk", "yarn", "play", "bite", "calm",
        "dash", "ears", "fawn", "glow", "hush",

        // 5-letter
        "beach", "charm", "dance", "flock", "grape",
        "happy", "jelly", "knack", "lemon", "mango",
        "ocean", "piano", "quest", "rover", "snack",
        "toast", "unity", "vivid", "world", "youth",
        "bliss", "crane", "drift", "flame", "gleam",
        "hound", "ivory", "joker", "kites", "lunar",

        // 6-letter
        "bridge", "candle", "dinner", "forest", "garden",
        "harbor", "island", "jungle", "kitten", "locket",
        "meadow", "nuzzle", "orange", "pillow", "quartz",
        "ribbon", "silver", "travel", "upbeat", "velvet",

        // 7-letter
        "balloon", "blanket", "chapter", "dolphin", "feather",
        "giraffe", "harmony", "journey", "lantern", "morning",
        "kitchen", "origami", "parasol", "quarter", "rainbow",
        "shelter", "thunder", "unicorn", "village", "whisper",

        // 8-letter
        "absolute", "bluebird", "calendar", "daffodil", "elephant",
        "flamingo", "gorgeous", "handbook", "jubilant", "keyboard",
        "keepsake", "lemonade", "mushroom", "notebook", "optimism",
        "peaceful", "treasure", "restless", "sandwich", "serenity",
    ]

    static func random(length: Int) -> String? {
        words.filter { $0.count == length }.randomElement()
    }
}
