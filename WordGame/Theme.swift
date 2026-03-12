import SwiftUI

enum Theme {
    static let correct = Color(red: 0.42, green: 0.75, blue: 0.48)
    static let present = Color(red: 0.93, green: 0.79, blue: 0.33)
    static let absent  = Color(red: 0.66, green: 0.66, blue: 0.68)

    static let tileEmpty  = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let tileBorder = Color(red: 0.82, green: 0.82, blue: 0.85)
    static let background = Color(red: 0.97, green: 0.96, blue: 0.98)
    static let accent     = Color(red: 0.58, green: 0.47, blue: 0.82)
    static let keyBg      = Color(red: 0.85, green: 0.85, blue: 0.88)

    static func color(for state: LetterState) -> Color {
        switch state {
        case .correct: return correct
        case .present: return present
        case .absent:  return absent
        case .unknown: return tileEmpty
        }
    }

    static func textColor(for state: LetterState) -> Color {
        state == .unknown ? .primary : .white
    }
}
