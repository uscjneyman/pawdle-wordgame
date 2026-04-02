//
//  WordGameTests.swift
//  WordGameTests
//
//  Created by Julia Neyman on 3/8/26.
//

import Testing
import Foundation
@testable import WordGame

struct WordGameTests {

    @Test("GameEngine handles duplicate letters correctly")
    func evaluateGuessWithDuplicates() {
        let result = GameEngine.evaluateGuess("allee", secret: "apple")
        let states = result.map(\.state)

        #expect(states.count == 5)
        #expect(states[0] == .correct)
        #expect(states[1] == .present)
        #expect(states[2] == .absent)
        #expect(states[3] == .absent)
        #expect(states[4] == .correct)
    }

    @Test("GameEngine score rewards quicker wins")
    func pawPointRewards() {
        #expect(GameEngine.pawPointsForWin(guesses: 1) == 5)
        #expect(GameEngine.pawPointsForWin(guesses: 2) == 4)
        #expect(GameEngine.pawPointsForWin(guesses: 3) == 3)
        #expect(GameEngine.pawPointsForWin(guesses: 4) == 2)
        #expect(GameEngine.pawPointsForWin(guesses: 5) == 1)
    }

    @Test("Sync classifier identifies true offline errors")
    func offlineErrorClassification() {
        let offline = URLError(.notConnectedToInternet)
        let timeout = URLError(.timedOut)
        let unrelated = NSError(domain: "com.pawdle.test", code: 42)

        #expect(SyncErrorClassifier.isLikelyOffline(offline))
        #expect(SyncErrorClassifier.isLikelyOffline(timeout))
        #expect(!SyncErrorClassifier.isLikelyOffline(unrelated))
    }

    @Test("RiddleService fetchRiddle parses and normalizes API answers")
    @MainActor
    func riddleServiceFetchRiddle() async {
        let session = makeMockSession { request in
            let json = """
            {
              "category": "animals",
              "length": 3,
              "difficulty": "easy",
              "riddle": "I purr and chase mice.",
              "answer": "The Cat!"
            }
            """
            return (200, Data(json.utf8))
        }

        let service = RiddleService(baseURL: "https://example.com", session: session)
        let result = await service.fetchRiddle(
            wordLength: 3,
            difficulty: 1,
            category: .animals,
            excluding: []
        )

        #expect(result?.riddle == "I purr and chase mice.")
        #expect(result?.answer == "cat")
    }

    @Test("RiddleService fetchPoolTotal aggregates totals  across random categories")
    @MainActor
    func riddleServiceFetchPoolTotalRandomCategory() async {
        let session = makeMockSession { request in
            let category = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "category" })?
                .value

            let total: Int
            switch category {
            case "animals": total = 4
            case "mystery": total = 3
            case "science": total = 5
            default: total = 0
            }

            let json = "{\"total\":\(total)}"
            return (200, Data(json.utf8))
        }

        let service = RiddleService(baseURL: "https://example.com", session: session)
        let total = await service.fetchPoolTotal(wordLength: 5, difficulty: 2, category: .random)

        #expect(total == 12)
    }

    @Test("SupabaseAuthService signIn decodes access token and user")
    @MainActor
    func supabaseSignInParsesSession() async throws {
        let session = makeMockSession { request in
            let path = request.url?.path ?? ""
            if path.contains("/auth/v1/token") {
                let json = """
                {
                  "access_token": "token-123",
                  "expires_in": 3600,
                  "user": { "id": "11111111-1111-4111-8111-111111111111", "email": "test@example.com" }
                }
                """
                return (200, Data(json.utf8))
            }

            return (404, Data("{}".utf8))
        }

        let service = SupabaseAuthService(session: session)
        let result = try await service.signIn(email: "test@example.com", password: "secret123")

        #expect(result.isAuthenticated)
        #expect(result.accessToken == "token-123")
        #expect(result.userId == "11111111-1111-4111-8111-111111111111")
        #expect(result.email == "test@example.com")
    }

    @Test("SupabaseAuthService signUp falls back to immediate signIn when session is absent")
    @MainActor
    func supabaseSignUpAutoLoginFallback() async throws {
        let session = makeMockSession { request in
            let path = request.url?.path ?? ""

            if path.contains("/auth/v1/signup") {
                let json = """
                {
                  "user": { "id": "22222222-2222-4222-8222-222222222222", "email": "new@example.com" }
                }
                """
                return (200, Data(json.utf8))
            }

            if path.contains("/auth/v1/token") {
                let json = """
                {
                  "access_token": "token-after-signup",
                  "expires_in": 3600,
                  "user": { "id": "22222222-2222-4222-8222-222222222222", "email": "new@example.com" }
                }
                """
                return (200, Data(json.utf8))
            }

            return (404, Data("{}".utf8))
        }

        let service = SupabaseAuthService(session: session)
        let result = try await service.signUp(email: "new@example.com", password: "secret123")

        #expect(result.isAuthenticated)
        #expect(result.accessToken == "token-after-signup")
        #expect(result.message == "Account created.")
    }

    @Test("Won word always uses riddle answer")
    @MainActor
    func gameSessionWordMatchesRiddleAnswer() async {
        let expectedAnswer = "otter"
        let vm = GameViewModel(
            dictionaryService: MockDictionaryService(),
            riddleService: MockRiddleService(
                riddle: "I hold hands while floating.",
                answer: expectedAnswer,
                total: 10
            )
        )

        vm.wordLength = expectedAnswer.count
        vm.difficulty = 1
        vm.category = .animals

        vm.startNewGame()

        for _ in 0..<20 where vm.isLoading {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(vm.session?.secretWord == expectedAnswer)
        #expect(vm.riddleText?.contains("I hold hands while floating.") == true)
    }

}

private struct MockDictionaryService: DictionaryProviding {
    func fetchDefinition(for word: String) async -> String {
        "mock"
    }
}

private struct MockRiddleService: RiddleProviding {
    let riddle: String
    let answer: String
    let total: Int

    func fetchRiddle(
        wordLength: Int,
        difficulty: Int,
        category: WordCategory,
        excluding excludedWords: Set<String>
    ) async -> (riddle: String, answer: String)? {
        guard answer.count == wordLength else { return nil }
        guard !excludedWords.contains(answer) else { return nil }
        return (riddle, answer)
    }

    func fetchPoolTotal(wordLength: Int, difficulty: Int, category: WordCategory) async -> Int? {
        total
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            fatalError("MockURLProtocol.handler was not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeMockSession(
    _ resolver: @escaping (URLRequest) -> (Int, Data)
) -> URLSession {
    MockURLProtocol.handler = { request in
        let (code, data) = resolver(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: code,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, data)
    }

    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}
