import Foundation

struct AuthResult {
    let isAuthenticated: Bool
    let userId: String?
    let email: String?
    let message: String?
    let accessToken: String?
    let expiresAt: Date?
}

enum AuthServiceError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Supabase auth is not configured."
        case .invalidResponse:
            return "Unexpected response from auth server."
        case .server(let message):
            return message
        }
    }
}

final class SupabaseAuthService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signIn(email: String, password: String) async throws -> AuthResult {
        let payload = ["email": email, "password": password]
        let response: SessionResponse = try await sendAuthRequest(
            path: "/auth/v1/token?grant_type=password",
            payload: payload,
            responseType: SessionResponse.self
        )

        let normalizedEmail = response.user?.email ?? email
        let expiry = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }

        return AuthResult(
            isAuthenticated: !(response.accessToken?.isEmpty ?? true),
            userId: response.user?.id,
            email: normalizedEmail,
            message: nil,
            accessToken: response.accessToken,
            expiresAt: expiry
        )
    }

    func signUp(email: String, password: String) async throws -> AuthResult {
        var payload = ["email": email, "password": password]
        if let redirectURL = AppConfig.supabaseEmailRedirectTo {
            payload["email_redirect_to"] = redirectURL
        }
        let response: SessionResponse = try await sendAuthRequest(
            path: "/auth/v1/signup",
            payload: payload,
            responseType: SessionResponse.self
        )

        let hasSession = !(response.accessToken?.isEmpty ?? true)
        let expiry = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        let normalizedEmail = response.user?.email ?? email

        if hasSession {
            return AuthResult(
                isAuthenticated: true,
                userId: response.user?.id,
                email: normalizedEmail,
                message: "Account created.",
                accessToken: response.accessToken,
                expiresAt: expiry
            )
        }

        // If sign-up does not return a session, try immediate sign-in so the app can continue.
        if let signedIn = try? await signIn(email: email, password: password), signedIn.isAuthenticated {
            return AuthResult(
                isAuthenticated: true,
                userId: signedIn.userId,
                email: signedIn.email ?? normalizedEmail,
                message: "Account created.",
                accessToken: signedIn.accessToken,
                expiresAt: signedIn.expiresAt
            )
        }

        return AuthResult(
            isAuthenticated: false,
            userId: response.user?.id,
            email: normalizedEmail,
            message: "Account created, but auto login failed. Please tap Log In.",
            accessToken: response.accessToken,
            expiresAt: expiry
        )
    }

    private func sendAuthRequest<T: Decodable>(
        path: String,
        payload: [String: String],
        responseType: T.Type
    ) async throws -> T {
        guard
            let baseURL = AppConfig.supabaseURL,
            let anonKey = AppConfig.supabaseAnonKey,
            !anonKey.isEmpty
        else {
            throw AuthServiceError.invalidConfiguration
        }

        guard let endpoint = URL(string: baseURL + path) else {
            throw AuthServiceError.invalidConfiguration
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                throw AuthServiceError.server(apiError.readableMessage)
            }
            throw AuthServiceError.server("Auth failed with status \(http.statusCode).")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AuthServiceError.invalidResponse
        }
    }
}

private struct SessionResponse: Decodable {
    let accessToken: String?
    let expiresIn: Int?
    let user: SessionUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case user
    }
}

private struct SessionUser: Decodable {
    let id: String?
    let email: String?
}

private struct AuthErrorResponse: Decodable {
    let error: String?
    let errorDescription: String?
    let message: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
        case msg
    }

    var readableMessage: String {
        if let errorDescription, !errorDescription.isEmpty { return errorDescription }
        if let message, !message.isEmpty { return message }
        if let msg, !msg.isEmpty { return msg }
        if let error, !error.isEmpty { return error }
        return "Authentication failed."
    }
}
