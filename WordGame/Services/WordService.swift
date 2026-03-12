import Foundation

enum WordServiceError: LocalizedError {
    case invalidURL
    case badResponse
    case noWord

    var errorDescription: String? {
        switch self {
        case .invalidURL:   return "Invalid URL"
        case .badResponse:  return "Bad server response"
        case .noWord:       return "No word returned"
        }
    }
}

struct WordService {

    // Datamuse response model
    private struct DatamuseWord: Decodable {
        let word: String
        let tags: [String]?
    }

    /// Fetch a word for the given category, length, and difficulty.
    ///
    /// **Category flow** (animals, food, nature, etc.):
    ///   1. Pick a random seed from the category's curated seed list.
    ///   2. Call Datamuse `ml={seed}` to find semantically related words.
    ///   3. Filter to nouns of the right length with decent frequency.
    ///   4. Combine API results with seed list, pick randomly.
    ///
    /// **Random flow**: Uses Datamuse wildcard `?` pattern with frequency bands.
    func fetchWord(length: Int, difficulty: Int, category: WordCategory) async throws -> String {
        if category == .random {
            return try await fetchRandomWord(length: length, difficulty: difficulty)
        }
        return try await fetchCategoryWord(length: length, difficulty: difficulty, category: category)
    }

    // MARK: - Category-based fetch

    private func fetchCategoryWord(length: Int, difficulty: Int, category: WordCategory) async throws -> String {
        let seeds = category.seedWords(forLength: length)

        // Try the API with a random seed
        if let seed = seeds.randomElement() {
            let pattern = String(repeating: "?", count: length)
            let urlString = "https://api.datamuse.com/words?ml=\(seed)&sp=\(pattern)&md=fp&max=300"

            if let url = URL(string: urlString) {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)

                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode) else {
                        throw WordServiceError.badResponse
                    }

                    let results = try JSONDecoder().decode([DatamuseWord].self, from: data)

                    // Build a set of ALL seed words for this length to boost category relevance
                    let seedSet = Set(seeds)
                    let (minFreq, _) = categoryFrequencyRange(for: difficulty)

                    // Collect candidates: API words that are nouns + seeds
                    var candidates = Set<String>()

                    for entry in results {
                        let word = entry.word.lowercased()
                        guard word.count == length,
                              word.allSatisfy({ $0.isASCII && $0.isLetter }) else { continue }

                        let freq = parseFrequency(from: entry.tags)
                        let isNoun = entry.tags?.contains("n") ?? false

                        // Accept if it's a seed word (always good) or a noun with enough frequency
                        if seedSet.contains(word) {
                            candidates.insert(word)
                        } else if isNoun && freq >= minFreq {
                            candidates.insert(word)
                        }
                    }

                    // Always add seed words as candidates too
                    for s in seeds { candidates.insert(s) }

                    if let picked = candidates.randomElement() {
                        return picked
                    }
                } catch {
                    // Fall through to seed-only fallback
                }
            }
        }

        // Fallback: pick from seed list directly
        if let picked = seeds.randomElement() {
            return picked
        }
        throw WordServiceError.noWord
    }

    // MARK: - Random (uncategorized) fetch

    private func fetchRandomWord(length: Int, difficulty: Int) async throws -> String {
        let pattern = String(repeating: "?", count: length)
        let urlString = "https://api.datamuse.com/words?sp=\(pattern)&md=fp&max=1000"

        guard let url = URL(string: urlString) else {
            throw WordServiceError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw WordServiceError.badResponse
            }

            let results = try JSONDecoder().decode([DatamuseWord].self, from: data)

            let (minFreq, maxFreq) = randomFrequencyRange(for: difficulty)

            let candidates = results.compactMap { entry -> String? in
                let word = entry.word.lowercased()
                guard word.count == length,
                      word.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }

                // Must be a noun, verb, or adjective (no adverbs, no function words)
                let pos = entry.tags?.filter { ["n", "v", "adj"].contains($0) } ?? []
                guard !pos.isEmpty else { return nil }

                let freq = parseFrequency(from: entry.tags)
                guard freq >= minFreq && freq < maxFreq else { return nil }
                return word
            }

            if let picked = candidates.randomElement() {
                return picked
            }
        } catch {
            // Fall through to fallback
        }

        if let fallback = FallbackWords.random(length: length) {
            return fallback
        }
        throw WordServiceError.noWord
    }

    // MARK: - Helpers

    /// Minimum frequency for category words by difficulty.
    /// Category words are already filtered by the seed/ml query, so we just
    /// need a loose frequency floor to exclude truly obscure terms.
    private func categoryFrequencyRange(for difficulty: Int) -> (min: Double, max: Double) {
        switch difficulty {
        case 1:  return (3.0, Double.infinity)   // Easy
        case 2:  return (1.0, Double.infinity)   // Medium
        default: return (0.3, Double.infinity)   // Hard
        }
    }

    /// Frequency ranges for the random (uncategorized) mode.
    private func randomFrequencyRange(for difficulty: Int) -> (min: Double, max: Double) {
        switch difficulty {
        case 1:  return (15.0, Double.infinity)  // Easy: very common
        case 2:  return (5.0, 15.0)              // Medium
        default: return (1.0, 5.0)               // Hard
        }
    }

    /// Extract the frequency value from Datamuse tags like ["f:42.5"].
    private func parseFrequency(from tags: [String]?) -> Double {
        guard let tags else { return 0 }
        for tag in tags {
            if tag.hasPrefix("f:"), let val = Double(tag.dropFirst(2)) {
                return val
            }
        }
        return 0
    }
}
