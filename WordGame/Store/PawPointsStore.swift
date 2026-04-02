import SwiftUI
import Combine

/// Persists the player's paw-point balance to UserDefaults.
/// Players start with 2 paw points (enough for 2 reveals).
/// Winning games earns more; each paw reveal costs 1 point.
@MainActor
final class PawPointsStore: ObservableObject {
    @Published private(set) var balance: Int

    private let key = "pawdle_paw_points"

    init() {
        let stored = UserDefaults.standard.object(forKey: key) as? Int
        balance = stored ?? 2
    }

    func earn(_ points: Int) {
        guard points > 0 else { return }
        balance += points
        save()
    }

    @discardableResult
    func spend(_ cost: Int = 1) -> Bool {
        guard balance >= cost else { return false }
        balance -= cost
        save()
        return true
    }

    func setBalance(_ newValue: Int) {
        let clamped = max(0, newValue)
        guard clamped != balance else { return }
        balance = clamped
        save()
    }

    private func save() {
        UserDefaults.standard.set(balance, forKey: key)
    }
}
