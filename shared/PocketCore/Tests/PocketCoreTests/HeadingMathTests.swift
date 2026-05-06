import XCTest
@testable import PocketCore

final class HeadingMathTests: XCTestCase {
    func test_magneticToTrue_with_positive_declination() {
        XCTAssertEqual(HeadingMath.magneticToTrue(magneticDegrees: 0, declination: 13), 13, accuracy: 1e-9)
        XCTAssertEqual(HeadingMath.magneticToTrue(magneticDegrees: 350, declination: 13), 3, accuracy: 1e-9)
    }

    func test_magneticToTrue_with_negative_declination() {
        XCTAssertEqual(HeadingMath.magneticToTrue(magneticDegrees: 10, declination: -13), 357, accuracy: 1e-9)
    }

    func test_bearing_san_francisco_to_new_york() {
        let sf = GeoCoordinate(latitude: 37.7749, longitude: -122.4194)
        let nyc = GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        let bearing = HeadingMath.bearingBetween(sf, nyc)
        // Initial great-circle bearing SF→NYC ≈ 70°.
        XCTAssertEqual(bearing, 70, accuracy: 2)
    }

    func test_cardinal_labels() {
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 0),   "N")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 45),  "NE")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 90),  "E")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 135), "SE")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 180), "S")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 225), "SW")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 270), "W")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 315), "NW")
        XCTAssertEqual(HeadingMath.cardinalLabel(forDegrees: 360), "N")
    }

    func test_normalize_handles_negatives_and_overflow() {
        XCTAssertEqual(HeadingMath.normalize(-10), 350, accuracy: 1e-9)
        XCTAssertEqual(HeadingMath.normalize(720),   0, accuracy: 1e-9)
        XCTAssertEqual(HeadingMath.normalize(45),   45, accuracy: 1e-9)
    }
}
