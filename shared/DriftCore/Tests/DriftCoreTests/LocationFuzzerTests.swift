import XCTest
@testable import DriftCore

final class LocationFuzzerTests: XCTestCase {

    func testTruncateZipReturnsExactly3Chars() {
        XCTAssertEqual(LocationFuzzer.truncateZip("94025"), "940")
        XCTAssertEqual(LocationFuzzer.truncateZip("94025-1234"), "940")
    }

    func testTruncateZipNilOrShort() {
        XCTAssertNil(LocationFuzzer.truncateZip(nil))
        XCTAssertNil(LocationFuzzer.truncateZip(""))
        XCTAssertNil(LocationFuzzer.truncateZip("12"))
    }

    func testFuzzedLocationNeverContainsCoordinateFields() {
        // The struct's stored properties are exactly three. Adding a lat/lon
        // would compile-time fail this test by changing the JSON shape.
        let fuzzed = LocationFuzzer.fuzz(zip5: "94025", countyFips: "06085", stateCode: "ca")
        let data = try! JSONEncoder.driftDefault.encode(fuzzed)
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNil(dict["lat"])
        XCTAssertNil(dict["lon"])
        XCTAssertEqual(dict.keys.sorted(), ["county_fips","state_code","zip_prefix3"])
    }

    func testFuzzNormalisesStateAndValidatesCounty() {
        let fuzzed = LocationFuzzer.fuzz(zip5: "94025", countyFips: "06085", stateCode: "ca")
        XCTAssertEqual(fuzzed.zipPrefix3, "940")
        XCTAssertEqual(fuzzed.countyFips, "06085")
        XCTAssertEqual(fuzzed.stateCode, "CA")
    }

    func testFuzzRejectsBadCountyAndState() {
        let fuzzed = LocationFuzzer.fuzz(zip5: nil, countyFips: "ABC", stateCode: "California")
        XCTAssertNil(fuzzed.zipPrefix3)
        XCTAssertNil(fuzzed.countyFips)
        XCTAssertNil(fuzzed.stateCode)
    }

    func testValidateCoordinateRejectsOutOfRange() {
        XCTAssertTrue(LocationFuzzer.validateCoordinate(lat: 37.4, lon: -122.1))
        XCTAssertFalse(LocationFuzzer.validateCoordinate(lat: 999, lon: 0))
        XCTAssertFalse(LocationFuzzer.validateCoordinate(lat: 0, lon: -200))
        XCTAssertFalse(LocationFuzzer.validateCoordinate(lat: .nan, lon: 0))
    }
}
