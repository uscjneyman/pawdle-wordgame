import Foundation
import Combine

@MainActor
final class CommunityStore: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = CommunityService()

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await service.fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func publish(userId: String, username: String, wonWord: WonWord, accessToken: String) async -> Bool {
        do {
            try await service.publish(userId: userId, username: username, wonWord: wonWord, accessToken: accessToken)
            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
