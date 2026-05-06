import Foundation
import CoreMotion
import PocketCore

@MainActor
final class AttitudeService: ObservableObject {
    @Published var pitchRoll: PitchRoll = PitchRoll(pitchDegrees: 0, rollDegrees: 0)

    private let motion = CMMotionManager()

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] dm, _ in
            guard let self, let g = dm?.gravity else { return }
            self.pitchRoll = LevelMath.pitchRoll(fromGravityX: g.x, gy: g.y, gz: g.z)
        }
    }

    func stop() { motion.stopDeviceMotionUpdates() }
}
