import Foundation

// MARK: - Response types

private struct DictionaryEntry: Decodable {
    let meanings: [Meaning]?

    struct Meaning: Decodable {
        let definitions: [Definition]?

        struct Definition: Decodable {
            let definition: String?
        }
    }
}

// MARK: - Service

struct DictionaryService {
    /// Fetch the first available definition for a word. Never throws – returns a fallback string on failure.
    func fetchDefinition(for word: String) async -> String {
        let cleaned = word.lowercased().filter { $0.isASCII && $0.isLetter }
        guard !cleaned.isEmpty,
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(cleaned)") else {
            return "No definition found."
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return "No definition found."
            }

            let entries = try JSONDecoder().decode([DictionaryEntry].self, from: data)
            if let def = entries.first?.meanings?.first?.definitions?.first?.definition {
                return def
            }
        } catch { /* swallow – we return a safe fallback */ }

        return "No definition found."
    }
}
