import Foundation
#if canImport(GroupActivities)
import GroupActivities
import FitFusionCore

/// SharePlay shared workout. Conforms to `GroupActivity` so two friends in
/// FaceTime can both schedule the same `WorkoutTemplate` simultaneously.
///
/// On reception, `SharedWorkoutView` lets each peer tap "I'm in"; both
/// devices then call `WorkoutScheduler.shared.schedule(template:at:)` so the
/// workout appears in both Apple Watch Workout apps at the same start time.
@available(iOS 17.0, *)
public struct SharedWorkoutActivity: GroupActivity {

    public let templateId: String

    public init(templateId: String) {
        self.templateId = templateId
    }

    public var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.title = template?.name ?? "MyHealth Workout"
        meta.subtitle = template.map { "\($0.durationMin) min \u{00b7} \($0.category.label)" } ?? "Train together"
        meta.type = .generic
        return meta
    }

    public var template: WorkoutTemplate? {
        WorkoutLibrary.templates.first { $0.id == templateId }
    }
}
#endif
