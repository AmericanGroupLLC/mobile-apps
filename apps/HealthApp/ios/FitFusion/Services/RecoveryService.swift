import Foundation
import FitFusionCore

/// Reads HRV, resting HR, sleep duration; produces a 0–100 recovery score
/// and a one-line suggestion (separate from server-side readiness).
@MainActor
final class RecoveryService {
    static let shared = RecoveryService()
    private init() {}

    struct Recovery {
        let score: Int
        let suggestion: String
        let hrvAvg: Double?
        let restingHr: Double?
        let sleepHours: Double?
    }

    func compute(using hk: iOSHealthKitManager) async throws -> Recovery {
        let hrv = await hk.averageHRV()
        let rhr = await hk.averageRestingHR()
        let snap = (try? await hk.fetchLastNightSleep())?.totalHours

        var score: Double = 50
        if let h = hrv {
            score += max(0, min(1, (h - 30) / 50)) * 25
        }
        if let r = rhr {
            // Lower RHR → better. Reasonable resting HR range: 45–80 bpm.
            let rhrNorm = max(0, min(1, (80 - r) / 35))
            score += rhrNorm * 15
        }
        if let s = snap {
            let delta = abs(s - 8)
            score += max(0, 1 - delta / 4) * 15
        }

        let value = Int(max(0, min(100, score.rounded())))
        let suggestion: String
        switch value {
        case 80...: suggestion = "You're well recovered — great day to train hard."
        case 60...: suggestion = "Recovery is solid — moderate intensity recommended."
        case 40...: suggestion = "Mixed recovery — keep things easy and hydrate."
        default:    suggestion = "Body is taxed — prioritize sleep and active recovery."
        }

        return .init(score: value,
                     suggestion: suggestion,
                     hrvAvg: hrv,
                     restingHr: rhr,
                     sleepHours: snap)
    }
}
