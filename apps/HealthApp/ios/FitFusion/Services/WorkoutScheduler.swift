import Foundation
import HealthKit
import FitFusionCore
#if canImport(WorkoutKit)
import WorkoutKit
#endif

/// Wraps WorkoutKit's `WorkoutScheduler.shared.schedule(...)` so the user can tap
/// "Send to Watch" in the iPhone's Train tab and have the workout appear in the
/// Apple Watch Workout app.
///
/// Falls back to a no-op (with a logged warning) when WorkoutKit isn't available.
@MainActor
final class WorkoutScheduler {
    static let shared = WorkoutScheduler()
    private init() {}

    func schedule(template: WorkoutTemplate, at date: Date) async {
        await schedule(template: template, at: date, adaptiveOverride: nil)
    }

    /// Schedule with an optional adaptive override emitted by the on-device
    /// `AdaptivePlanner`. When provided, the override duration / intensity
    /// supersedes the template's defaults so the Watch's structured workout
    /// reflects what the model thinks the user should actually do today.
    func schedule(template: WorkoutTemplate,
                  at date: Date,
                  adaptiveOverride: AdaptiveOverride?) async {
        #if canImport(WorkoutKit)
        guard #available(iOS 17.0, *) else { return }
        do {
            let activity = HKWorkoutActivityType(rawValue: UInt(template.activityType)) ?? .traditionalStrengthTraining
            let workoutPlan = workoutKitPlan(for: template, activity: activity, override: adaptiveOverride)
            let schedule = WorkoutKit.WorkoutSchedule(start: date, recurrence: nil)
            let scheduledWorkout = WorkoutKit.ScheduledWorkoutPlan(workoutPlan, scheduledAt: schedule)
            try await WorkoutKit.WorkoutScheduler.shared.schedule(scheduledWorkout)
        } catch {
            print("[WorkoutScheduler] schedule failed: \(error)")
        }
        #else
        print("[WorkoutScheduler] WorkoutKit unavailable — skipping schedule.")
        #endif
    }

    struct AdaptiveOverride: Sendable {
        let durationMin: Int?
        let confidence: Double
        let rationale: String
    }

    #if canImport(WorkoutKit)
    @available(iOS 17.0, *)
    private func workoutKitPlan(for template: WorkoutTemplate,
                                activity: HKWorkoutActivityType,
                                override: AdaptiveOverride? = nil) -> WorkoutKit.WorkoutPlan {
        let minutes = override?.durationMin ?? template.durationMin
        let single = SingleGoalWorkout(
            activity: activity,
            location: .indoor,
            warmup: nil,
            block: IntervalBlock(steps: [
                IntervalStep(.work, goal: .time(Double(minutes) * 60, .seconds))
            ], iterations: 1),
            cooldown: nil
        )
        return WorkoutKit.WorkoutPlan(.single(single), id: UUID())
    }
    #endif
}
