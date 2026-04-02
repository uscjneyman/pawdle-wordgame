import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var currentEmail: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = SupabaseAuthService()

    private let tokenKey = "auth.accessToken"
    private let expiryKey = "auth.expiresAt"
    private let userIdKey = "auth.userId"
    private let emailKey = "auth.email"

    var accessToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    init() {
        restoreSession()
    }

    func signIn(email: String, password: String) async -> Bool {
        await submit(email: email, password: password, mode: .signIn)
    }

    func signUp(email: String, password: String) async -> Bool {
        await submit(email: email, password: password, mode: .signUp)
    }

    func signOut() {
        isAuthenticated = false
        currentUserId = nil
        currentEmail = nil
        errorMessage = nil
        clearStoredSession()
    }

    private enum Mode {
        case signIn
        case signUp
    }

    private func submit(email: String, password: String, mode: Mode) async -> Bool {
        guard !isLoading else { return false }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result: AuthResult
            switch mode {
            case .signIn:
                result = try await authService.signIn(email: email, password: password)
            case .signUp:
                result = try await authService.signUp(email: email, password: password)
            }

            currentEmail = result.email ?? email
            currentUserId = result.userId

            if result.isAuthenticated {
                persistSession(
                    token: result.accessToken,
                    expiresAt: result.expiresAt,
                    userId: result.userId,
                    email: currentEmail
                )
                isAuthenticated = true
                return true
            }

            isAuthenticated = false
            errorMessage = result.message ?? "Authentication failed. Please try again."
            return false
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func restoreSession() {
        let defaults = UserDefaults.standard
        let expiry = defaults.object(forKey: expiryKey) as? Date
        let token = defaults.string(forKey: tokenKey)
        let userId = defaults.string(forKey: userIdKey)

        guard
            let expiry,
            let token,
            !token.isEmpty,
            let userId,
            !userId.isEmpty,
            expiry > Date()
        else {
            clearStoredSession()
            isAuthenticated = false
            return
        }

        currentUserId = userId
        currentEmail = defaults.string(forKey: emailKey)
        isAuthenticated = true
    }

    private func persistSession(token: String?, expiresAt: Date?, userId: String?, email: String?) {
        guard let token, let expiresAt, let userId, !userId.isEmpty else { return }
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: tokenKey)
        defaults.set(expiresAt, forKey: expiryKey)
        defaults.set(userId, forKey: userIdKey)
        defaults.set(email, forKey: emailKey)
    }

    private func clearStoredSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: expiryKey)
        defaults.removeObject(forKey: userIdKey)
        defaults.removeObject(forKey: emailKey)
    }
}
