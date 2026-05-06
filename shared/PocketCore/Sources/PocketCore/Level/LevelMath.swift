// LevelMath — pure pitch/roll + bubble offset math. No CoreMotion imports;
// platform layer feeds in attitude.
import Foundation

public struct PitchRoll: Equatable, Sendable {
    public let pitchDegrees: Double  // tilt forward/back
    public let rollDegrees: Double   // tilt left/right
    public init(pitchDegrees: Double, rollDegrees: Double) {
        self.pitchDegrees = pitchDegrees
        self.rollDegrees = rollDegrees
    }
}

public enum LevelMath {
    /// Compute pitch / roll in degrees from a normalized gravity vector
    /// `(gx, gy, gz)` where ‖g‖ = 1 (e.g. iOS attitude.gravity or Android
    /// SENSOR_TYPE_GRAVITY scaled).
    public static func pitchRoll(fromGravityX gx: Double, gy: Double, gz: Double) -> PitchRoll {
        // Atan2-based: standard accelerometer-pitch/roll derivation.
        let pitch = atan2(-gx, sqrt(gy * gy + gz * gz)) * 180 / .pi
        let roll  = atan2(gy, gz) * 180 / .pi
        return PitchRoll(pitchDegrees: pitch, rollDegrees: roll)
    }

    /// Convert a pitch/roll into an (x, y) offset, in points, for drawing the
    /// bullseye bubble. The bubble travels at most `radius` points off-center
    /// at ±`maxAngle` (default 30°).
    public static func bubbleOffset(forPitch pitch: Double, roll: Double, radius: Double, maxAngle: Double = 30) -> (x: Double, y: Double) {
        let clampedRoll  = max(-maxAngle, min(maxAngle, roll))
        let clampedPitch = max(-maxAngle, min(maxAngle, pitch))
        let scale = radius / maxAngle
        return (x: clampedRoll * scale, y: clampedPitch * scale)
    }

    /// Returns true when the device is roughly horizontal (face-up or face-down).
    public static func isFlat(pitch: Double, roll: Double, threshold: Double = 30) -> Bool {
        abs(pitch) < threshold && abs(roll) < threshold
    }
}
