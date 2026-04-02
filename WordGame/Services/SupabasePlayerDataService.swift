import Foundation

struct PlayerSnapshot {
    let pawPoints: Int?
    let wonWords: [WonWord]
}

enum PlayerDataSyncError: LocalizedError {
    case invalidConfiguration
    case invalidUserId
    case invalidURL
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Supabase data sync is not configured."
        case .invalidUserId:
            return "Invalid user identifier for sync."
        case .invalidURL:
            return "Invalid Supabase URL."
        case .requestFailed(let code, let detail):
            return "Sync failed with status \(code): \(detail)"
        }
    }
}

final class SupabasePlayerDataService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func syncAll(userId: String, accessToken: String, pawPoints: Int, wonWords: [WonWord]) async throws {
        guard UUID(uuidString: userId) != nil else {
            throw PlayerDataSyncError.invalidUserId
        }
        try await upsertProfile(userId: userId, accessToken: accessToken, pawPoints: pawPoints)
        if !wonWords.isEmpty {
            try await upsertWonWords(userId: userId, accessToken: accessToken, wonWords: wonWords)
        }
    }

    func fetchSnapshot(userId: String, accessToken: String) async throws -> PlayerSnapshot {
        guard UUID(uuidString: userId) != nil else {
            throw PlayerDataSyncError.invalidUserId
        }
        async let profile = fetchProfile(userId: userId, accessToken: accessToken)
        async let words = fetchWonWords(userId: userId, accessToken: accessToken)
        return try await PlayerSnapshot(pawPoints: profile, wonWords: words)
    }

    private func upsertProfile(userId: String, accessToken: String, pawPoints: Int) async throws {
        let body: [[String: Any]] = [[
            "user_id": userId,
            "paw_points": pawPoints,
            "updated_at": Self.iso8601.string(from: Date())
        ]]

        try await sendRequest(
            method: "POST",
            path: "/rest/v1/player_profiles",
            queryItems: [URLQueryItem(name: "on_conflict", value: "user_id")],
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=minimal",
            body: body
        )
    }

    private func upsertWonWords(userId: String, accessToken: String, wonWords: [WonWord]) async throws {
        let body = wonWords.compactMap { makeWonWordPayload(userId: userId, wonWord: $0) }
        guard !body.isEmpty else { return }

        do {
            try await sendRequest(
                method: "POST",
                path: "/rest/v1/won_words",
                queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
                accessToken: accessToken,
                prefer: "resolution=merge-duplicates,return=minimal",
                body: body
            )
            return
        } catch let PlayerDataSyncError.requestFailed(code, _) where code == 400 {
            // Some legacy rows can fail validation; retry one-by-one so valid rows still sync.
            var successCount = 0
            var lastError: Error?

            for payload in body {
                do {
                    try await sendRequest(
                        method: "POST",
                        path: "/rest/v1/won_words",
                        queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
                        accessToken: accessToken,
                        prefer: "resolution=merge-duplicates,return=minimal",
                        body: [payload]
                    )
                    successCount += 1
                } catch {
                    lastError = error
                }
            }

            if successCount > 0 {
                return
            }

            if let lastError {
                throw lastError
            }

            throw PlayerDataSyncError.requestFailed(400, "All won_words rows failed validation during sync.")
        }

        catch {
            throw error
        }
    }

    private func makeWonWordPayload(userId: String, wonWord: WonWord) -> [String: Any]? {
        let normalizedWord = wonWord.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedWord.isEmpty else { return nil }
        guard wonWord.tries > 0, wonWord.maxAttempts > 0 else { return nil }

        var payload: [String: Any] = [
            "id": wonWord.id.uuidString.lowercased(),
            "user_id": userId,
            "word": normalizedWord,
            "tries": wonWord.tries,
            "max_attempts": wonWord.maxAttempts,
            "won_at": Self.iso8601.string(from: wonWord.date),
            "sticker_id": wonWord.sticker.id,
            "sticker_name": wonWord.sticker.name,
            "sticker_emoji": wonWord.sticker.emoji,
            "sticker_rarity": wonWord.sticker.rarity.rawValue
        ]

        if let pawPoints = wonWord.pawPoints {
            payload["paw_points_earned"] = pawPoints
        }
        if let category = wonWord.category {
            payload["category"] = category
        }
        if let difficulty = wonWord.difficulty {
            payload["difficulty"] = difficulty
        }
        if let wordLength = wonWord.wordLength {
            payload["word_length"] = wordLength
        }

        return payload
    }

    private func fetchProfile(userId: String, accessToken: String) async throws -> Int? {
        let data = try await sendRequest(
            method: "GET",
            path: "/rest/v1/player_profiles",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "select", value: "paw_points"),
                URLQueryItem(name: "limit", value: "1")
            ],
            accessToken: accessToken,
            prefer: nil,
            body: nil
        )

        let decoded = try JSONDecoder().decode([ProfileRow].self, from: data)
        return decoded.first?.pawPoints
    }

    private func fetchWonWords(userId: String, accessToken: String) async throws -> [WonWord] {
        let data = try await sendRequest(
            method: "GET",
            path: "/rest/v1/won_words",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "select", value: "id,word,tries,max_attempts,won_at,sticker_id,sticker_name,sticker_emoji,sticker_rarity,paw_points_earned,category,difficulty,word_length"),
                URLQueryItem(name: "order", value: "won_at.desc"),
                URLQueryItem(name: "limit", value: "1000")
            ],
            accessToken: accessToken,
            prefer: nil,
            body: nil
        )

        let rows = try JSONDecoder().decode([WonWordRow].self, from: data)
        return rows.compactMap { row in
            guard let id = UUID(uuidString: row.id) else { return nil }
            let sticker = Sticker(
                id: row.stickerId,
                name: row.stickerName,
                emoji: row.stickerEmoji,
                rarity: StickerRarity(rawValue: row.stickerRarity) ?? .common
            )

            return WonWord(
                id: id,
                word: row.word,
                tries: row.tries,
                maxAttempts: row.maxAttempts,
                date: Self.parseDate(row.wonAt) ?? Date(),
                sticker: sticker,
                pawPoints: row.pawPointsEarned,
                category: row.category,
                difficulty: row.difficulty,
                wordLength: row.wordLength
            )
        }
    }

    @discardableResult
    private func sendRequest(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        accessToken: String,
        prefer: String?,
        body: Any?
    ) async throws -> Data {
        guard
            let baseURLString = AppConfig.supabaseURL,
            let anonKey = AppConfig.supabaseAnonKey,
            !anonKey.isEmpty
        else {
            throw PlayerDataSyncError.invalidConfiguration
        }

        guard let baseURL = URL(string: baseURLString) else {
            throw PlayerDataSyncError.invalidURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw PlayerDataSyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PlayerDataSyncError.requestFailed(-1, "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw PlayerDataSyncError.requestFailed(http.statusCode, detail)
        }

        return data
    }
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601NoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func parseDate(_ value: String) -> Date? {
        iso8601.date(from: value) ?? iso8601NoFractional.date(from: value)
    }
}

private struct ProfileRow: Decodable {
    let pawPoints: Int

    enum CodingKeys: String, CodingKey {
        case pawPoints = "paw_points"
    }
}

private struct WonWordRow: Decodable {
    let id: String
    let word: String
    let tries: Int
    let maxAttempts: Int
    let wonAt: String
    let stickerId: String
    let stickerName: String
    let stickerEmoji: String
    let stickerRarity: String
    let pawPointsEarned: Int?
    let category: String?
    let difficulty: Int?
    let wordLength: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case word
        case tries
        case maxAttempts = "max_attempts"
        case wonAt = "won_at"
        case stickerId = "sticker_id"
        case stickerName = "sticker_name"
        case stickerEmoji = "sticker_emoji"
        case stickerRarity = "sticker_rarity"
        case pawPointsEarned = "paw_points_earned"
        case category
        case difficulty
        case wordLength = "word_length"
    }
}
