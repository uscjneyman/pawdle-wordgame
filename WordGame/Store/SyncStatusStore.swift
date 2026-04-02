import Foundation
import SwiftUI
import Combine

@MainActor
final class SyncStatusStore: ObservableObject {
    enum State: Equatable {
        case idle
        case syncing
        case synced(Date)
        case pendingOffline
        case failed

        var label: String {
            switch self {
            case .idle:
                return "Sync idle"
            case .syncing:
                return "Syncing..."
            case .synced(let date):
                return "Synced \(Self.timeString(from: date))"
            case .pendingOffline:
                return "Offline: pending sync"
            case .failed:
                return "Sync failed"
            }
        }

        var icon: String {
            switch self {
            case .idle:
                return "icloud"
            case .syncing:
                return "arrow.triangle.2.circlepath"
            case .synced:
                return "checkmark.icloud"
            case .pendingOffline:
                return "icloud.slash"
            case .failed:
                return "exclamationmark.icloud"
            }
        }

        var color: Color {
            switch self {
            case .idle:
                return .secondary
            case .syncing:
                return .blue
            case .synced:
                return .green
            case .pendingOffline:
                return .orange
            case .failed:
                return .red
            }
        }

        private static func timeString(from date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        }
    }

    @Published var state: State = .idle
    @Published var lastErrorMessage: String?

    func reset() {
        state = .idle
        lastErrorMessage = nil
    }

    func markSynced(at date: Date = Date()) {
        state = .synced(date)
        lastErrorMessage = nil
    }

    func markOffline(error: Error? = nil) {
        state = .pendingOffline
        lastErrorMessage = error?.localizedDescription
    }

    func markFailed(_ error: Error) {
        state = .failed
        lastErrorMessage = error.localizedDescription
    }
}
