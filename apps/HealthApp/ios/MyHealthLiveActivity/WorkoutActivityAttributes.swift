import ActivityKit
import Foundation

/// `ActivityAttributes` for an in-progress workout mirrored from the Apple
/// Watch to the iPhone via `HKWorkoutSession.startMirroringToCompanionDevice()`.
/// Drives the Lock Screen + Dynamic Island Live Activity in
/// `WorkoutLiveActivity.swift`.
public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var elapsedSeconds: TimeInterval
        public var heartRate: Double
        public var calories: Double
        public var distanceMeters: Double
        public var activityIcon: String

        public init(elapsedSeconds: TimeInterval,
                    heartRate: Double,
                    calories: Double,
                    distanceMeters: Double,
                    activityIcon: String) {
            self.elapsedSeconds = elapsedSeconds
            self.heartRate = heartRate
            self.calories = calories
            self.distanceMeters = distanceMeters
            self.activityIcon = activityIcon
        }
    }

    public let workoutName: String
    public let startedAt: Date

    public init(workoutName: String, startedAt: Date) {
        self.workoutName = workoutName
        self.startedAt = startedAt
    }
}
