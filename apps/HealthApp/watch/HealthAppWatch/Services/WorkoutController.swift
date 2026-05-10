import Foundation
import HealthKit
import WatchKit
import FitFusionCore

/// Wraps an HKWorkoutSession + HKLiveWorkoutBuilder for the watch's Live Workout UI.
///
/// New in MyHealth 5-layer architecture:
///   * Always-on display is enabled at session start (extended runtime is implicit
///     for `HKWorkoutSession` while in `.running` state).
///   * On iOS 17 / watchOS 10, the session calls
///     `startMirroringToCompanionDevice()` so the iPhone can present a mirrored
///     `MirroredWorkoutView` and the ActivityKit Live Activity stays in sync.
///   * Per-second snapshots of HR / calories / elapsed are written to the App
///     Group `UserDefaults` (`group.com.fitfusion`) so the iOS Live Activity and
///     widgets read them without needing WatchConnectivity.
///
/// On end, posts a `workout_minutes` metric to the backend so iOS readiness
/// reflects the strain.
@MainActor
final class WorkoutController: NSObject, ObservableObject {
    static let shared = WorkoutController()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var distanceMeters: Double = 0
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var isRunning = false
    @Published var lastError: String?

    private var startedAt: Date?
    private var timer: Timer?
    private var activityType: HKWorkoutActivityType = .traditionalStrengthTraining

    /// App Group key written each tick so Live Activity / widgets / iPhone sheet
    /// can read without a `WCSession` round-trip.
    static let appGroupID = "group.com.fitfusion"
    static let liveTickKey = "myhealth.liveWorkoutTick"

    func start(activityType: HKWorkoutActivityType = .traditionalStrengthTraining,
               location: HKWorkoutSessionLocationType = .indoor) {
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = location
        self.activityType = activityType

        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            startedAt = Date()
            isRunning = true
            distanceMeters = 0
            heartRate = 0
            activeCalories = 0

            s.startActivity(with: Date())
            b.beginCollection(withStart: Date()) { _, _ in }

            // Layer 4 (the moat): mirror the live session to the companion iPhone.
            if #available(watchOS 10.0, *) {
                s.startMirroringToCompanionDevice { [weak self] _, error in
                    if let error {
                        Task { @MainActor in self?.lastError = "Mirroring: \(error.localizedDescription)" }
                    }
                }
            }

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    if let s = self.startedAt {
                        self.elapsedSeconds = Date().timeIntervalSince(s)
                    }
                    self.publishLiveTick()
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func pause() { session?.pause() }
    func resume() { session?.resume() }

    func end() async -> HKWorkout? {
        timer?.invalidate(); timer = nil
        clearLiveTick()
        guard let s = session, let b = builder else { return nil }
        s.end()
        do {
            try await b.endCollection(at: Date())
            let workout = try await b.finishWorkout()
            isRunning = false
            session = nil
            builder = nil

            let minutes = (workout?.duration ?? elapsedSeconds) / 60.0
            _ = try? await APIClient.shared.logMetric(type: "workout_minutes",
                                                     value: minutes,
                                                     unit: "min")
            return workout
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - App Group live tick (consumed by iOS Live Activity / widgets)

    private func publishLiveTick() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        let payload: [String: Any] = [
            "ts": Date().timeIntervalSince1970,
            "elapsed": elapsedSeconds,
            "hr": heartRate,
            "calories": activeCalories,
            "distance": distanceMeters,
            "activity": activityType.rawValue,
            "isRunning": isRunning,
        ]
        defaults.set(payload, forKey: Self.liveTickKey)
    }

    private func clearLiveTick() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        defaults.removeObject(forKey: Self.liveTickKey)
    }
}

extension WorkoutController: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {}
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didFailWithError error: Error) {
        Task { @MainActor in self.lastError = error.localizedDescription }
    }
}

extension WorkoutController: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let qType = type as? HKQuantityType,
                  let stats = workoutBuilder.statistics(for: qType) else { continue }

            if qType == HKQuantityType(.heartRate) {
                let unit = HKUnit.count().unitDivided(by: .minute())
                let v = stats.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                Task { @MainActor in self.heartRate = v }
            } else if qType == HKQuantityType(.activeEnergyBurned) {
                let v = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor in self.activeCalories = v }
            } else if qType == HKQuantityType(.distanceWalkingRunning) {
                let v = stats.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                Task { @MainActor in self.distanceMeters = v }
            }
        }
    }
}
