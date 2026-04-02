import Foundation

final class CommunityService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Fetch posts (public, newest first)

    func fetchPosts(limit: Int = 100) async throws -> [CommunityPost] {
        let data = try await sendRequest(
            method: "GET",
            path: "/rest/v1/community_posts",
            queryItems: [
                URLQueryItem(name: "select", value: "id,user_id,username,word,tries,max_attempts,sticker_emoji,sticker_name,sticker_rarity,paw_points_earned,category,difficulty,word_length,created_at"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ],
            accessToken: nil,
            prefer: nil,
            body: nil
        )

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let d = Self.iso8601.date(from: str) { return d }
            if let d = Self.iso8601NoFractional.date(from: str) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }

        return try decoder.decode([CommunityPost].self, from: data)
    }

    // MARK: - Publish a post

    func publish(userId: String, username: String, wonWord: WonWord, accessToken: String) async throws {
        var payload: [String: Any] = [
            "user_id": userId,
            "username": username,
            "word": wonWord.word.lowercased(),
            "tries": wonWord.tries,
            "max_attempts": wonWord.maxAttempts,
            "sticker_emoji": wonWord.sticker.emoji,
            "sticker_name": wonWord.sticker.name,
            "sticker_rarity": wonWord.sticker.rarity.rawValue
        ]
        if let p = wonWord.pawPoints { payload["paw_points_earned"] = p }
        if let c = wonWord.category { payload["category"] = c }
        if let d = wonWord.difficulty { payload["difficulty"] = d }
        if let wl = wonWord.wordLength { payload["word_length"] = wl }

        try await sendRequest(
            method: "POST",
            path: "/rest/v1/community_posts",
            queryItems: [],
            accessToken: accessToken,
            prefer: "return=minimal",
            body: [payload]
        )
    }

    // MARK: - Networking

    @discardableResult
    private func sendRequest(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        accessToken: String?,
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

        var components = URLComponents(
            url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw PlayerDataSyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
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
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601NoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
