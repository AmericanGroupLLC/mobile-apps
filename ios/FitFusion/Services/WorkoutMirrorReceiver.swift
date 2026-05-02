import Foundation
import HealthKit
import Combine

/// iOS-side receiver for workout sessions mirrored from the paired Apple Watch
/// via `HKWorkoutSession.startMirroringToCompanionDevice()` (iOS 17 / watchOS 10).
///
/// Two ingestion paths feed the published live stats:
///
/// 1. **`HKWorkoutSessionMirroringStartHandler`** — observed via
///    `HKHealthStore.workoutSessionMirroringStartHandler`. When a watch session
///    starts mirroring, we associate ourselves as the companion-side
///    `HKLiveWorkoutBuilderDelegate` and forward `didCollectDataOf:` deltas.
///
/// 2. **App Group fallback** — the Watch's `WorkoutController` writes a
///    per-second tick to the shared `UserDefaults` suite `group.com.fitfusion`
///    (key `myhealth.liveWorkoutTick`). We poll this suite and surface it for
///    Live Activities / widgets that can't observe HealthKit directly.
///
/// `HomeDashboardView` observes `isActive` and presents `MirroredWorkoutView`
/// as a sheet whenever it flips to `true`.
@MainActor
final class WorkoutMirrorReceiver: NSObject, ObservableObject {

    static let shared = WorkoutMirrorReceiver()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var isActive = false
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var distanceMeters: Double = 0
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var activityIcon: String = "figure.strengthtraining.traditional"
    @Published var lastError: String?

    private var startedAt: Date?
    private var pollTimer: Timer?

    static let appGroupID = "group.com.fitfusion"
    static let liveTickKey = "myhealth.liveWorkoutTick"

    /// Starts listening for mirrored sessions. Call once at app start.
    func startObserving() {
        if #available(iOS 17.0, *) {
            store.workoutSessionMirroringStartHandler = { [weak self] session in
                Task { @MainActor in
                    self?.attach(session: session)
                }
            }
        }
        // Begin polling the App Group as a robust fallback so widgets/Live
        // Activity stay in sync even if HealthKit mirroring is delayed.
        startPolling()
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollAppGroup() }
        }
    }

    private func pollAppGroup() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let payload = defaults.dictionary(forKey: Self.liveTickKey) else {
            // No tick = no live workout from the watch right now.
            if isActive && session == nil {
                // Watch session ended without a HealthKit handshake. Reset.
                reset()
            }
            return
        }
        let running = (payload["isRunning"] as? Bool) ?? false
        if !running {
            reset()
            return
        }
        isActive = true
        elapsedSeconds = (payload["elapsed"] as? Double) ?? elapsedSeconds
        heartRate = (payload["hr"] as? Double) ?? heartRate
        activeCalories = (payload["calories"] as? Double) ?? activeCalories
        distanceMeters = (payload["distance"] as? Double) ?? distanceMeters
        if let raw = payload["activity"] as? UInt {
            activityIcon = Self.icon(for: raw)
        }
    }

    @available(iOS 17.0, *)
    private func attach(session: HKWorkoutSession) {
        self.session = session
        let builder = session.associatedWorkoutBuilder()
        builder.delegate = self
        self.builder = builder
        startedAt = Date()
        isActive = true
    }

    private func reset() {
        isActive = false
        session = nil
        builder = nil
        heartRate = 0
        activeCalories = 0
        distanceMeters = 0
        elapsedSeconds = 0
    }

    private static func icon(for raw: UInt) -> String {
        switch raw {
        case UInt(HKWorkoutActivityType.running.rawValue): return "figure.run"
        case UInt(HKWorkoutActivityType.cycling.rawValue): return "figure.outdoor.cycle"
        case UInt(HKWorkoutActivityType.yoga.rawValue): return "figure.yoga"
        case UInt(HKWorkoutActivityType.functionalStrengthTraining.rawValue),
             UInt(HKWorkoutActivityType.traditionalStrengthTraining.rawValue):
            return "figure.strengthtraining.traditional"
        default: return "figure.mixed.cardio"
        }
    }

    /// `AsyncSequence` view of the live tuple used by anything that prefers
    /// pull-style consumption (e.g. ActivityKit update loop).
    struct MirroredStats: Equatable {
        let elapsed: TimeInterval
        let hr: Double
        let calories: Double
        let distance: Double
    }

    var statsStream: AsyncStream<MirroredStats> {
        AsyncStream { continuation in
            let cancel = self.objectWillChange.sink { [weak self] _ in
                guard let self else { return }
                continuation.yield(.init(elapsed: self.elapsedSeconds,
                                         hr: self.heartRate,
                                         calories: self.activeCalories,
                                         distance: self.distanceMeters))
            }
            continuation.onTermination = { _ in cancel.cancel() }
        }
    }

    private var cancellables: Set<AnyCancellable> = []
}

// MARK: - HKLiveWorkoutBuilderDelegate (companion-side mirror)

extension WorkoutMirrorReceiver: HKLiveWorkoutBuilderDelegate {
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
