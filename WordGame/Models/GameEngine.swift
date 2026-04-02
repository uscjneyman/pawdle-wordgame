import Foundation

/// Pure game rules and scoring logic, independent of UI or networking.
enum GameEngine {
    static func evaluateGuess(_ guess: String, secret: String) -> [LetterResult] {
        let g = Array(guess)
        let s = Array(secret)
        let n = g.count
        var states = [LetterState](repeating: .absent, count: n)

        var remaining: [Character: Int] = [:]
        for c in s { remaining[c, default: 0] += 1 }

        for i in 0..<n where g[i] == s[i] {
            states[i] = .correct
            remaining[g[i], default: 0] -= 1
        }

        for i in 0..<n {
            guard states[i] != .correct else { continue }
            if remaining[g[i], default: 0] > 0 {
                states[i] = .present
                remaining[g[i]]! -= 1
            }
        }

        return (0..<n).map { LetterResult(letter: String(g[$0]), state: states[$0]) }
    }

    static func pawPointsForWin(guesses: Int) -> Int {
        switch guesses {
        case 1:  return 5
        case 2:  return 4
        case 3:  return 3
        case 4:  return 2
        default: return 1
        }
    }
}
