import Foundation
#if canImport(CoreML)
import CoreML
#endif

/// On-device adaptive workout planner.
///
/// Wraps a small bundled `AdaptivePlanner.mlmodel` (Create ML tabular regressor
/// trained offline on synthetic + open fitness data; ~1\u{2013}3 MB) and overlays the
/// cloud's heuristic readiness suggestion with a personalized confidence /
/// rationale. Inputs include readiness, recent HRV, sleep, and training load;
/// the output is the next `WorkoutTemplate` from the local `WorkoutLibrary`.
///
/// The Core ML asset itself is not committed in this plan execution \u{2014} the host
/// app falls back to a deterministic heuristic when the model file is missing
/// (so simulator builds still work) and `PersonalFineTuner` updates the asset
/// nightly via `MLUpdateTask`.
///
/// **Privacy:** all inputs and outputs stay on the device. Only the
/// `WorkoutTemplate.id` the user accepts is sent to the backend, identical to
/// today's behavior.
@MainActor
public final class AdaptivePlanner {

    public static let shared = AdaptivePlanner()

    public struct Suggestion: Sendable, Equatable {
        public let template: WorkoutTemplate
        public let confidence: Double          // 0...1
        public let rationale: String
    }

    public struct Inputs: Sendable {
        public let readiness: Int              // 0...100
        public let recentHRV: Double?          // ms
        public let lastSleepHrs: Double?       // hours
        public let weeklyMinutes: Double?      // training load this week
        public let perceivedExertion: Double?  // 1...10 RPE

        public init(readiness: Int, recentHRV: Double?, lastSleepHrs: Double?,
                    weeklyMinutes: Double?, perceivedExertion: Double?) {
            self.readiness = readiness
            self.recentHRV = recentHRV
            self.lastSleepHrs = lastSleepHrs
            self.weeklyMinutes = weeklyMinutes
            self.perceivedExertion = perceivedExertion
        }
    }

    private var modelURL: URL?

    private init() {
        self.modelURL = Bundle.main.url(forResource: "AdaptivePlanner", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "AdaptivePlanner", withExtension: "mlmodel")
    }

    /// Suggest the user's next workout. Pulls from `WorkoutLibrary.templates`.
    public func nextWorkout(for inputs: Inputs) -> Suggestion {
        // 1. Try Core ML when the model is present.
        if let url = modelURL,
           let model = try? MLModel(contentsOf: url),
           let suggestion = predict(with: model, inputs: inputs) {
            return suggestion
        }
        // 2. Heuristic fallback when no model is bundled (typical first-run /
        //    simulator path). Keeps the app shippable while offline training
        //    catches up.
        return heuristic(inputs: inputs)
    }

    /// Convenience wrapper used by `HomeDashboardView` when only readiness is known.
    public func nextWorkout(for readiness: Int) -> Suggestion {
        nextWorkout(for: .init(readiness: readiness,
                               recentHRV: nil, lastSleepHrs: nil,
                               weeklyMinutes: nil, perceivedExertion: nil))
    }

    // MARK: - Internals

    private func predict(with model: MLModel, inputs: Inputs) -> Suggestion? {
        // Generic feature dictionary \u{2014} the bundled `.mlmodel` is expected to
        // expose `readiness`, `hrv`, `sleep`, `weekly_minutes`, `rpe` features
        // and a `template_id` string output. If the bundled model has a
        // different shape, decoding fails and the caller falls back to the
        // heuristic path.
        let features: [String: MLFeatureValue] = [
            "readiness":       .init(double: Double(inputs.readiness)),
            "hrv":             .init(double: inputs.recentHRV ?? -1),
            "sleep":           .init(double: inputs.lastSleepHrs ?? -1),
            "weekly_minutes":  .init(double: inputs.weeklyMinutes ?? -1),
            "rpe":             .init(double: inputs.perceivedExertion ?? -1),
        ]
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: features),
              let out = try? model.prediction(from: provider),
              let templateId = out.featureValue(for: "template_id")?.stringValue,
              let template = WorkoutLibrary.templates.first(where: { $0.id == templateId }) else {
            return nil
        }
        let confidence = out.featureValue(for: "confidence")?.doubleValue ?? 0.6
        let rationale = out.featureValue(for: "rationale")?.stringValue
            ?? "Personalized for your recent data."
        return .init(template: template, confidence: max(0, min(1, confidence)), rationale: rationale)
    }

    private func heuristic(inputs: Inputs) -> Suggestion {
        let templates = WorkoutLibrary.templates
        let pick: WorkoutTemplate
        let rationale: String
        switch inputs.readiness {
        case 80...:
            pick = templates.first { $0.id == "advanced-strength-45" }
                ?? templates.first { $0.id == "tempo-run-25" }
                ?? templates[0]
            rationale = "High readiness \u{2014} push a heavy compound day."
        case 60..<80:
            pick = templates.first { $0.id == "full-body-strength-30" }
                ?? templates.first { $0.id == "hiit-cardio-15" }
                ?? templates[0]
            rationale = "Solid readiness \u{2014} a balanced full-body session."
        case 40..<60:
            pick = templates.first { $0.id == "easy-run-30" }
                ?? templates.first { $0.id == "vinyasa-flow-30" }
                ?? templates[0]
            rationale = "Mixed signals \u{2014} zone-2 cardio keeps the engine warm."
        default:
            pick = templates.first { $0.id == "gentle-yoga-20" }
                ?? templates.first { $0.id == "deep-stretch-25" }
                ?? templates[0]
            rationale = "Recovery day \u{2014} gentle mobility + breath work."
        }
        // Confidence scales with how much data we used.
        let dataPoints = [inputs.recentHRV, inputs.lastSleepHrs,
                          inputs.weeklyMinutes, inputs.perceivedExertion]
            .compactMap { $0 }.count
        let confidence = 0.55 + Double(dataPoints) * 0.08    // 0.55 \u{2026} 0.87
        return .init(template: pick, confidence: confidence, rationale: rationale)
    }
}
