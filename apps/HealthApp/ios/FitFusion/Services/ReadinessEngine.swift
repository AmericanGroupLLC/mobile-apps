import Foundation
import FitFusionCore

/// Heuristic readiness scorer using HRV trend + sleep hours + recent strain.
@MainActor
final class ReadinessEngine {
    static let shared = ReadinessEngine()
    private init() {}

    struct Score {
        let value: Int
        let suggestion: String
    }

    func compute(hrvAvg: Double?, sleepHrs: Double?, workoutMinutes: Double?) -> Score {
        var score: Double = 50
        if let h = hrvAvg {
            let hrvNorm = max(0, min(1, (h - 30) / 50))
            score += hrvNorm * 25
        }
        if let s = sleepHrs {
            let delta = abs(s - 8)
            let sleepNorm = max(0, 1 - delta / 4)
            score += sleepNorm * 20
        }
        if let w = workoutMinutes, w > 120 {
            score -= min(20, (w - 120) / 6)
        }
        let clamped = Int(max(0, min(100, score.rounded())))

        let suggestion: String
        switch clamped {
        case 80...:  suggestion = "Green light — go push it 💪"
        case 60...:  suggestion = "Solid day — moderate effort recommended"
        case 40...:  suggestion = "Mixed signals — keep it easy today"
        default:     suggestion = "Recovery day — prioritize sleep & gentle movement 🧘"
        }
        return .init(value: clamped, suggestion: suggestion)
    }
}
