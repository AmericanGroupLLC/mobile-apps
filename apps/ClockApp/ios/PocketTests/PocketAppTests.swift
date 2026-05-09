import XCTest
@testable import Pocket
import PocketCore

final class PocketAppTests: XCTestCase {
    func test_calculator_engine_round_trip() {
        XCTAssertEqual(CalculatorEngine.evaluate("2+2"), .number(4))
    }

    func test_heading_cardinal() {
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 0), "N")
    }

    func test_level_flat_at_zero() {
        let pr = LevelMath.pitchRoll(fromGravityX: 0, gy: 0, gz: 1)
        XCTAssertTrue(LevelMath.isFlat(pitch: pr.pitchDegrees, roll: pr.rollDegrees))
    }
}
