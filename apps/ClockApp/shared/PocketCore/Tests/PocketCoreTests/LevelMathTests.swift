import XCTest
@testable import PocketCore

final class LevelMathTests: XCTestCase {
    func test_perfectly_flat() {
        let pr = LevelMath.pitchRoll(fromGravityX: 0, gy: 0, gz: 1)
        XCTAssertEqual(pr.pitchDegrees, 0, accuracy: 1e-6)
        XCTAssertEqual(pr.rollDegrees, 0, accuracy: 1e-6)
        XCTAssertTrue(LevelMath.isFlat(pitch: pr.pitchDegrees, roll: pr.rollDegrees))
    }

    func test_rolled_right_45() {
        // gravity vector when rolled +45° around y axis
        let g = (x: 0.0, y: sin(Double.pi / 4), z: cos(Double.pi / 4))
        let pr = LevelMath.pitchRoll(fromGravityX: g.x, gy: g.y, gz: g.z)
        XCTAssertEqual(pr.rollDegrees, 45, accuracy: 1e-3)
    }

    func test_pitched_forward_30() {
        // gravity vector when pitched +30° around x axis
        let g = (x: -sin(Double.pi / 6), y: 0.0, z: cos(Double.pi / 6))
        let pr = LevelMath.pitchRoll(fromGravityX: g.x, gy: g.y, gz: g.z)
        XCTAssertEqual(pr.pitchDegrees, 30, accuracy: 1e-3)
    }

    func test_bubble_offset_proportional_within_bounds() {
        let zero = LevelMath.bubbleOffset(forPitch: 0, roll: 0, radius: 100)
        XCTAssertEqual(zero.x, 0, accuracy: 1e-9)
        XCTAssertEqual(zero.y, 0, accuracy: 1e-9)
        let mid = LevelMath.bubbleOffset(forPitch: 15, roll: 15, radius: 100, maxAngle: 30)
        XCTAssertEqual(mid.x, 50, accuracy: 1e-9)
        XCTAssertEqual(mid.y, 50, accuracy: 1e-9)
        let max = LevelMath.bubbleOffset(forPitch: 100, roll: -100, radius: 100, maxAngle: 30)
        XCTAssertEqual(max.x, -100, accuracy: 1e-9)
        XCTAssertEqual(max.y, 100, accuracy: 1e-9)
    }

    func test_isFlat_threshold() {
        XCTAssertTrue(LevelMath.isFlat(pitch: 5, roll: -5))
        XCTAssertFalse(LevelMath.isFlat(pitch: 45, roll: 0))
        XCTAssertFalse(LevelMath.isFlat(pitch: 0, roll: -45))
    }
}
