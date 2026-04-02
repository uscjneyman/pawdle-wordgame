import SwiftUI
import Combine
import Foundation

/// Persists WonWord records to UserDefaults as JSON.
@MainActor
final class WonWordsStore: ObservableObject {
    @Published private(set) var wonWords: [WonWord] = []

    private let key = "pawdle_won_words"

    init() { load() }

    func add(_ record: WonWord) {
        // Keep most recent wins at the top of the list.
        wonWords.insert(record, at: 0)   // newest first
        save()
    }

    func merge(_ records: [WonWord]) {
        guard !records.isEmpty else { return }

        var combined = Dictionary(uniqueKeysWithValues: wonWords.map { ($0.id, $0) })
        for record in records {
            combined[record.id] = record
        }

        wonWords = combined.values.sorted { $0.date > $1.date }
        save()
    }

    func replaceAll(_ records: [WonWord]) {
        let sorted = records.sorted { $0.date > $1.date }
        guard sorted != wonWords else { return }
        wonWords = sorted
        save()
    }

    func clearAll() {
        wonWords.removeAll()
        save()
    }

    func delete(atOffsets offsets: IndexSet) {
        // Supports swipe-to-delete from the list view.
        wonWords.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Persistence

    private func save() {
        // Persist as JSON for simple local storage without a database.
        guard let data = try? JSONEncoder().encode(wonWords) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        // If decoding fails, keep the default empty array.
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WonWord].self, from: data) else { return }
        wonWords = decoded
    }
}
