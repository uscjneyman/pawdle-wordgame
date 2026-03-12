import Foundation

enum WordCategory: String, CaseIterable, Codable {
    case animals
    case mystery
    case science
    case random

    var displayName: String {
        switch self {
        case .animals: return "Animals"
        case .mystery: return "Mystery"
        case .science: return "Science"
        case .random:  return "Random"
        }
    }

    var emoji: String {
        switch self {
        case .animals: return "🐾"
        case .mystery: return "🕵️"
        case .science: return "🔬"
        case .random:  return "🎲"
        }
    }

    /// Seed words used to query the Datamuse `ml=` endpoint.
    /// The API finds words semantically related to these seeds,
    /// yielding varied, category-relevant results each game.
    /// Seeds themselves are also valid answers as fallback.
    func seedWords(forLength length: Int) -> [String] {
        let all = seedPool
        return all.filter { $0.count == length }
    }

    private var seedPool: [String] {
        switch self {
        case .animals:
            return [
                // 4
                "bear", "bird", "crab", "crow", "deer", "duck", "fish", "frog", "goat", "hare",
                "lamb", "lion", "mole", "moth", "mule", "newt", "puma", "seal", "slug", "toad", "wasp", "wolf", "worm",
                // 5
                "bison", "camel", "eagle", "goose", "horse", "hyena", "koala", "llama", "moose", "mouse",
                "otter", "panda", "robin", "shark", "sheep", "snail", "snake", "stork", "tiger", "trout", "whale", "zebra",
                // 6
                "badger", "beaver", "donkey", "falcon", "ferret", "gopher", "iguana", "jaguar", "lizard", "monkey",
                "osprey", "parrot", "pigeon", "rabbit", "salmon", "turtle", "walrus", "weasel",
                // 7
                "buffalo", "cheetah", "chicken", "dolphin", "giraffe", "gorilla", "hamster", "leopard", "lobster",
                "panther", "peacock", "pelican", "penguin", "raccoon", "rooster", "sparrow",
                // 8
                "aardvark", "antelope", "elephant", "flamingo", "hedgehog", "kangaroo",
                "mongoose", "pheasant", "reindeer", "squirrel", "starfish",
            ]
        case .mystery:
            return [
                // 4
                "case", "clue", "code", "cold", "crypt", "hint", "knot", "lock", "mask", "note",
                "plot", "ruse", "scar", "seal", "sign", "trail", "trap", "veil",
                // 5
                "alias", "alibi", "chase", "crime", "diary", "enigma", "hunch", "knife", "morse", "motel",
                "print", "raven", "rumor", "scope", "shade", "shard", "smoke", "stain", "trace", "vault",
                // 6
                "cipher", "decode", "escape", "forger", "legend", "mystic", "napkin", "puzzle", "secret", "shadow",
                "signal", "suspect", "token", "voyage", "warden", "whodun",
                // 7
                "archive", "chimera", "detects", "evidence", "hideout", "message", "mystery", "phantom", "pursuit",
                "riddler", "secrecy", "theorem", "tracker", "unknown",
                // 8
                "backroom", "cloaking", "darkness", "disguise", "evidence", "keyholes", "lockpick", "midnight",
                "riddling", "suspense", "treasure", "whispers",
            ]
        case .science:
            return [
                // 4
                "atom", "cell", "gene", "heat", "mass", "moon", "nova", "quark", "wave", "zinc",
                // 5
                "anode", "boson", "comet", "delta", "epoch", "focal", "laser", "neutr", "orbit", "phase",
                "plasm", "qubit", "radar", "sonar", "toxin", "vapor",
                // 6
                "apogee", "buffer", "cosmos", "enzyme", "fusion", "galaxy", "molecule", "neuron", "oxygen", "photon",
                "plasma", "sample", "tensor", "vacuum",
                // 7
                "biology", "calcium", "circuit", "element", "gravity", "isotope", "journal", "physics", "protein",
                "quantum", "science", "theorem", "uranium", "voltage",
                // 8
                "asteroid", "electron", "evidence", "magnetic", "molecule", "neutron", "research", "spectrum",
                "telescope", "velocity",
            ]
        case .random:
            return []
        }
    }
}
