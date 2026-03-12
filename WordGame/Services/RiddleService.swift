import Foundation

/// Fetches riddles from the custom Heroku-hosted Pawdle Riddle API.
/// The riddle's answer becomes the word the player must guess.
struct RiddleService {

    // MARK: - Config

    private let baseURL = "https://pawdle-riddle-api-jneyman-8d9a88151bf0.herokuapp.com"

    // MARK: - Response types

    private struct APIResponse: Decodable {
        let category: String
        let length: Int
        let difficulty: String
        let riddle: String
        let answer: String
    }

    private struct ListResponse: Decodable {
        let total: Int
    }

    // MARK: - Public API

    /// Fetch a riddle whose answer matches the requested length.
    /// Solved words are sent to the API for server-side exclusion.
    func fetchRiddle(
        wordLength: Int,
        difficulty: Int,
        category: WordCategory,
        excluding excludedWords: Set<String>
    ) async -> (riddle: String, answer: String)? {
        let categories = apiCategories(for: category)

        for selectedCategory in categories.shuffled() {
            guard let request = makeRandomRequest(
                    wordLength: wordLength,
                    difficulty: difficulty,
                    apiCategory: selectedCategory,
                    excluding: excludedWords
                  ) else {
                return nil
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("[RiddleService] ❌ HTTP \(code) for category \(selectedCategory)")
                    continue
                }

                let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
                let cleaned = normalizeAnswer(decoded.answer)

                guard cleaned.count == wordLength,
                      !excludedWords.contains(cleaned) else {
                    print("[RiddleService] ⏭ API returned excluded or mismatched answer: \"\(decoded.answer)\"")
                    continue
                }

                print("[RiddleService] ✅ Found: \"\(decoded.riddle.prefix(60))...\" → \(cleaned)")
                return (decoded.riddle, cleaned)
            } catch {
                print("[RiddleService] ❌ Error for category \(selectedCategory): \(error.localizedDescription)")
            }
        }

        print("[RiddleService] ⚠️ No suitable riddle found")
        return nil
    }

    /// Count riddles in the current configured pool.
    func fetchPoolTotal(wordLength: Int, difficulty: Int, category: WordCategory) async -> Int? {
        let categories = apiCategories(for: category)
        var total = 0

        for apiCategory in categories {
            guard let request = makeListRequest(
                wordLength: wordLength,
                difficulty: difficulty,
                apiCategory: apiCategory
            ) else {
                return nil
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    return nil
                }

                let decoded = try JSONDecoder().decode(ListResponse.self, from: data)
                total += decoded.total
            } catch {
                return nil
            }
        }

        return total
    }

    // MARK: - Helpers

    private func makeRandomRequest(
        wordLength: Int,
        difficulty: Int,
        apiCategory: String,
        excluding excludedWords: Set<String>
    ) -> URLRequest? {
        let excludedValue = excludedWords.sorted().joined(separator: ",")
        var components = URLComponents(string: "\(baseURL)/api/riddles/random")
        components?.queryItems = [
            URLQueryItem(name: "category", value: apiCategory),
            URLQueryItem(name: "difficulty", value: apiDifficulty(for: difficulty)),
            URLQueryItem(name: "length", value: String(wordLength)),
            URLQueryItem(name: "exclude", value: excludedValue.isEmpty ? nil : excludedValue)
        ]

        guard let url = components?.url else { return nil }
        return URLRequest(url: url)
    }

    private func makeListRequest(wordLength: Int, difficulty: Int, apiCategory: String) -> URLRequest? {
        var components = URLComponents(string: "\(baseURL)/api/riddles")
        components?.queryItems = [
            URLQueryItem(name: "category", value: apiCategory),
            URLQueryItem(name: "difficulty", value: apiDifficulty(for: difficulty)),
            URLQueryItem(name: "length", value: String(wordLength)),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components?.url else { return nil }
        return URLRequest(url: url)
    }

    private func apiDifficulty(for appDifficulty: Int) -> String {
        switch appDifficulty {
        case 1: return "easy"
        case 2: return "medium"
        default: return "hard"
        }
    }

    private func apiCategories(for category: WordCategory) -> [String] {
        switch category {
        case .animals:
            return ["animals"]
        case .mystery:
            return ["mystery"]
        case .science:
            return ["science"]
        case .random:
            return ["animals", "mystery", "science"]
        }
    }

    /// Normalizes API answer text for gameplay comparison/storage.
    private func normalizeAnswer(_ raw: String) -> String {
        var candidate = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Remove a few common leading articles that appear in riddle answers.
        for prefix in ["a ", "an ", "the "] {
            if candidate.hasPrefix(prefix) {
                candidate.removeFirst(prefix.count)
                break
            }
        }

        // Keep letters only; API data is expected to be single-word answers.
        return candidate.filter { $0.isLetter }
    }

    /// Fallback clue when riddle fetch fails and we use WordService instead.
    func fallbackRiddle(for word: String, difficulty: Int, category: WordCategory) -> String {
        let n = word.count
        let first = String(word.prefix(1)).uppercased()

        switch difficulty {
        case 1:
            if category != .random {
                return "I'm a \(n)-letter \(category.displayName.lowercased()) word that starts with \"\(first)\". Can you guess me?"
            }
            return "I'm a \(n)-letter word that starts with \"\(first)\". Can you figure me out?"
        case 2:
            if category != .random {
                return "I'm a \(n)-letter word hiding in the \(category.displayName.lowercased()) category. Think carefully!"
            }
            return "I'm a mystery word with \(n) letters. Pay attention to the colors!"
        default:
            return "I won't give you much — just \(n) letters stand between you and victory."
        }
    }
}
