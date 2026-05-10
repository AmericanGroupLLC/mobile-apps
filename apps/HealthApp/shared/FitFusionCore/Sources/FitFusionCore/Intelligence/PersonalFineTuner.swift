import Foundation
#if canImport(CoreML)
import CoreML
#endif
#if os(iOS) || os(tvOS)
import BackgroundTasks
#endif

/// Schedules and runs an `MLUpdateTask` over a window of recent
/// (HRV, sleep, planned vs actual workout, perceived exertion) tuples to
/// personalize the bundled `AdaptivePlanner` model. Runs nightly via
/// `BGTaskScheduler` (`com.fitfusion.bg.fineTune`).
///
/// All training data and the updated model artifact stay on the device \u{2014}
/// nothing is uploaded.
public final class PersonalFineTuner {

    public static let shared = PersonalFineTuner()
    private init() {}

    /// Identifier registered with `BGTaskScheduler` in `FitFusionApp`.
    public static let backgroundTaskIdentifier = "com.fitfusion.bg.fineTune"

    /// One training example \u{2014} the caller assembles a window of these from
    /// HealthKit (HRV, last night sleep) plus CloudKit (planned workout) plus
    /// the user's RPE log.
    public struct Sample: Sendable {
        public let hrv: Double
        public let sleepHours: Double
        public let plannedTemplateId: String
        public let actualTemplateId: String?
        public let rpe: Double?

        public init(hrv: Double, sleepHours: Double,
                    plannedTemplateId: String, actualTemplateId: String?, rpe: Double?) {
            self.hrv = hrv
            self.sleepHours = sleepHours
            self.plannedTemplateId = plannedTemplateId
            self.actualTemplateId = actualTemplateId
            self.rpe = rpe
        }
    }

    /// Schedule the next nightly fine-tune. No-op when BackgroundTasks is unavailable.
    public func scheduleNextRun(after delay: TimeInterval = 60 * 60 * 12) {
        #if os(iOS) || os(tvOS)
        let request = BGProcessingTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true   // train while charging overnight
        request.earliestBeginDate = Date(timeIntervalSinceNow: delay)
        try? BGTaskScheduler.shared.submit(request)
        #endif
    }

    /// Entry point invoked by the BGTaskScheduler launch handler. Performs an
    /// `MLUpdateTask` using the supplied samples and persists a personalized
    /// model into the app's caches dir under `AdaptivePlanner.personalized.mlmodelc`.
    @discardableResult
    public func fineTune(samples: [Sample]) async -> Bool {
        guard !samples.isEmpty else { return false }
        guard let modelURL = Bundle.main.url(forResource: "AdaptivePlanner",
                                             withExtension: "mlmodelc") else {
            // No bundled updatable model \u{2014} skip silently.
            return false
        }

        let provider = try? MLArrayBatchProvider(dictionary: featureBatch(from: samples))
        guard let provider else { return false }

        return await withCheckedContinuation { cont in
            let progress: (MLUpdateContext) -> Void = { _ in /* progress handler */ }
            do {
                let task = try MLUpdateTask(forModelAt: modelURL,
                                            trainingData: provider,
                                            configuration: nil) { context in
                    let target = self.personalizedURL()
                    do {
                        try context.model.write(to: target)
                        cont.resume(returning: true)
                    } catch {
                        cont.resume(returning: false)
                    }
                }
                _ = progress
                task.resume()
            } catch {
                cont.resume(returning: false)
            }
        }
    }

    private func featureBatch(from samples: [Sample]) -> [String: [MLFeatureValue]] {
        var hrv: [MLFeatureValue] = []
        var sleep: [MLFeatureValue] = []
        var planned: [MLFeatureValue] = []
        var actual: [MLFeatureValue] = []
        var rpe: [MLFeatureValue] = []
        for s in samples {
            hrv.append(.init(double: s.hrv))
            sleep.append(.init(double: s.sleepHours))
            planned.append(.init(string: s.plannedTemplateId))
            actual.append(.init(string: s.actualTemplateId ?? s.plannedTemplateId))
            rpe.append(.init(double: s.rpe ?? -1))
        }
        return [
            "hrv": hrv, "sleep": sleep,
            "planned": planned, "actual": actual,
            "rpe": rpe,
        ]
    }

    private func personalizedURL() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("AdaptivePlanner.personalized.mlmodelc")
    }
}
