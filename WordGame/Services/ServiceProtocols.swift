import Foundation

protocol DictionaryProviding {
    func fetchDefinition(for word: String) async -> String
}

protocol RiddleProviding {
    func fetchRiddle(
        wordLength: Int,
        difficulty: Int,
        category: WordCategory,
        excluding excludedWords: Set<String>
    ) async -> (riddle: String, answer: String)?

    func fetchPoolTotal(wordLength: Int, difficulty: Int, category: WordCategory) async -> Int?
}
