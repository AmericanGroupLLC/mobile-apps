import Foundation

/// On-device heuristic biological-age estimator.
///
/// Inspired by published "biological age" approaches (PhenoAge, Klemera-Doubal,
/// resting-HR / HRV / VO\u{2082}Max regressions) but **simplified** so it runs in
/// pure Swift on a watch, with **no network, no third-party model, no medical
/// claim**. Each input nudges the chronological age up or down by a small,
/// transparent number of years; the breakdown is exposed to the UI so users
/// see *why* a number was assigned.
///
/// **Honest disclaimer:** this is an estimate for personal motivation, not
/// a clinical diagnosis. Don't make medical decisions from it.
public struct BiologicalAgeEngine {

    public static let shared = BiologicalAgeEngine()
    public init() {}

    // MARK: - Inputs

    public struct Inputs: Sendable, Hashable {
        public let chronologicalYears: Double
        public let sex: Sex
        public let restingHR: Double?           // bpm
        public let hrv: Double?                 // ms (SDNN)
        public let vo2Max: Double?              // ml/kg/min
        public let avgSleepHours: Double?       // h / night, 7-day avg
        public let bmi: Double?                 // kg/m\u{00b2}
        public let bodyFatPct: Double?          // 0\u{2013}1
        public let systolicBP: Double?          // mmHg
        public let diastolicBP: Double?         // mmHg
        public let weeklyExerciseMin: Double?   // min / week
        public let stepsPerDay: Double?
        public let smoker: Bool
        public let heavyAlcohol: Bool

        public init(chronologicalYears: Double, sex: Sex,
                    restingHR: Double? = nil, hrv: Double? = nil,
                    vo2Max: Double? = nil, avgSleepHours: Double? = nil,
                    bmi: Double? = nil, bodyFatPct: Double? = nil,
                    systolicBP: Double? = nil, diastolicBP: Double? = nil,
                    weeklyExerciseMin: Double? = nil, stepsPerDay: Double? = nil,
                    smoker: Bool = false, heavyAlcohol: Bool = false) {
            self.chronologicalYears = chronologicalYears
            self.sex = sex
            self.restingHR = restingHR
            self.hrv = hrv
            self.vo2Max = vo2Max
            self.avgSleepHours = avgSleepHours
            self.bmi = bmi
            self.bodyFatPct = bodyFatPct
            self.systolicBP = systolicBP
            self.diastolicBP = diastolicBP
            self.weeklyExerciseMin = weeklyExerciseMin
            self.stepsPerDay = stepsPerDay
            self.smoker = smoker
            self.heavyAlcohol = heavyAlcohol
        }
    }

    public enum Sex: String, Codable, Sendable {
        case male, female, other
    }

    // MARK: - Output

    public struct Result: Sendable, Hashable {
        public let chronologicalYears: Double
        public let biologicalYears: Double
        public let confidence: Double           // 0\u{2013}1 \u{2014} scales with #signals available
        public let factors: [Factor]

        public var deltaYears: Double { biologicalYears - chronologicalYears }
        public var verdict: String {
            switch deltaYears {
            case ..<(-3): return "Significantly younger than your age \u{1F680}"
            case (-3)..<(-0.5): return "Younger than your age \u{2728}"
            case (-0.5)..<0.5: return "Right on track"
            case 0.5..<3: return "Slightly older than your age"
            case 3..<7: return "Notably older \u{2014} worth attention"
            default: return "Much older \u{2014} consider lifestyle changes \u{26A0}\u{fe0f}"
            }
        }
    }

    public struct Factor: Sendable, Hashable, Identifiable {
        public let id = UUID()
        public let name: String
        public let value: String      // human-readable input value, e.g. "62 bpm"
        public let deltaYears: Double // negative = makes you younger
        public let direction: Direction

        public enum Direction: String, Sendable { case better, neutral, worse }
    }

    // MARK: - Compute

    public func estimate(_ inputs: Inputs) -> Result {
        var factors: [Factor] = []

        if let rhr = inputs.restingHR {
            // Each bpm above 60 adds ~0.15 yr; below 60 subtracts up to ~3 yr.
            let delta = (rhr - 60) * 0.15
            factors.append(.init(
                name: "Resting HR",
                value: "\(Int(rhr)) bpm",
                deltaYears: clamp(delta, -3, 5),
                direction: deltaSign(delta)
            ))
        }
        if let hrv = inputs.hrv {
            // Higher HRV = younger. Sweet spot ~50 ms; each 10 ms above subtracts ~0.6 yr.
            let delta = -((hrv - 35) / 10.0) * 0.6
            factors.append(.init(
                name: "HRV (SDNN)",
                value: "\(Int(hrv)) ms",
                deltaYears: clamp(delta, -3, 4),
                direction: deltaSign(delta)
            ))
        }
        if let vo2 = inputs.vo2Max {
            // VO\u{2082}Max population norm depends on sex+age; rough penalty if low.
            let target = inputs.sex == .female ? 32.0 : 38.0
            let delta = -((vo2 - target) / 5.0) * 0.7
            factors.append(.init(
                name: "VO\u{2082} Max",
                value: String(format: "%.1f ml/kg/min", vo2),
                deltaYears: clamp(delta, -4, 5),
                direction: deltaSign(delta)
            ))
        }
        if let sleep = inputs.avgSleepHours {
            // Optimal ~7.5 h. Each hour off the optimal in either direction adds ~0.5 yr.
            let off = abs(sleep - 7.5)
            let delta = off * 0.5
            factors.append(.init(
                name: "Avg sleep",
                value: String(format: "%.1f h", sleep),
                deltaYears: clamp(delta, 0, 4),
                direction: off < 0.5 ? .better : (off < 1.0 ? .neutral : .worse)
            ))
        }
        if let bmi = inputs.bmi {
            // Healthy BMI 18.5\u{2013}24.9 = 0; outside that band penalises ~0.4 yr per unit.
            let delta: Double
            if bmi < 18.5 { delta = (18.5 - bmi) * 0.4 }
            else if bmi > 25 { delta = (bmi - 25) * 0.4 }
            else { delta = 0 }
            factors.append(.init(
                name: "BMI",
                value: String(format: "%.1f", bmi),
                deltaYears: clamp(delta, 0, 5),
                direction: delta > 0.5 ? .worse : .neutral
            ))
        }
        if let bf = inputs.bodyFatPct {
            // Healthy body fat depends on sex; rough heuristic.
            let target = inputs.sex == .female ? 0.25 : 0.18
            let delta = max(0, bf - target) * 25
            factors.append(.init(
                name: "Body fat",
                value: String(format: "%.0f%%", bf * 100),
                deltaYears: clamp(delta, 0, 4),
                direction: delta > 0.3 ? .worse : .neutral
            ))
        }
        if let sys = inputs.systolicBP {
            // Above 130 / under 90 worsens score.
            let delta: Double
            if sys > 130 { delta = (sys - 130) / 10.0 * 0.7 }
            else if sys < 90 { delta = (90 - sys) / 10.0 * 0.5 }
            else { delta = 0 }
            factors.append(.init(
                name: "Blood pressure",
                value: "\(Int(sys))/\(Int(inputs.diastolicBP ?? 0)) mmHg",
                deltaYears: clamp(delta, 0, 4),
                direction: delta > 0.5 ? .worse : .neutral
            ))
        }
        if let exMin = inputs.weeklyExerciseMin {
            // 150 min / week target.
            let delta = -(min(exMin, 300) - 150) / 50.0 * 0.6
            factors.append(.init(
                name: "Weekly exercise",
                value: "\(Int(exMin)) min / wk",
                deltaYears: clamp(delta, -2.5, 2.5),
                direction: deltaSign(delta)
            ))
        }
        if let steps = inputs.stepsPerDay {
            let delta = -(min(steps, 12000) - 7500) / 1500.0 * 0.4
            factors.append(.init(
                name: "Daily steps",
                value: "\(Int(steps))",
                deltaYears: clamp(delta, -1.5, 2),
                direction: deltaSign(delta)
            ))
        }
        if inputs.smoker {
            factors.append(.init(name: "Smoking", value: "Yes",
                                 deltaYears: 6, direction: .worse))
        }
        if inputs.heavyAlcohol {
            factors.append(.init(name: "Heavy alcohol", value: "Yes",
                                 deltaYears: 3, direction: .worse))
        }

        let totalDelta = factors.reduce(0) { $0 + $1.deltaYears }
        let bio = max(15, min(120, inputs.chronologicalYears + totalDelta))

        // Confidence is the share of signals provided (chronological + sex always count).
        let provided = factors.count
        let possible = 11.0   // 9 numerics + 2 booleans
        let confidence = max(0.2, min(1.0, Double(provided) / possible))

        return Result(
            chronologicalYears: inputs.chronologicalYears,
            biologicalYears: bio,
            confidence: confidence,
            factors: factors.sorted { abs($0.deltaYears) > abs($1.deltaYears) }
        )
    }

    // MARK: - Helpers

    private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }
    private func deltaSign(_ d: Double) -> Factor.Direction {
        d < -0.25 ? .better : (d > 0.25 ? .worse : .neutral)
    }
}
