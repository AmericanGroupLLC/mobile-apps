import XCTest
@testable import PocketCore

final class AlarmStoreTests: XCTestCase {
    func test_load_returns_empty_when_no_file() throws {
        let dir = try makeTempDir()
        let store = AlarmStore(directory: dir, filename: "missing.json")
        XCTAssertTrue(store.load().isEmpty)
    }

    func test_save_then_load_roundtrips() throws {
        let dir = try makeTempDir()
        let store = AlarmStore(directory: dir, filename: "alarms.json")
        let originals = [
            Alarm(label: "Wake up", hour: 7, minute: 30, repeatOn: [.mon, .tue, .wed, .thu, .fri]),
            Alarm(label: "Lunch", hour: 12, minute: 0, repeatOn: [], soundName: "chime", enabled: false)
        ]
        try store.save(originals)
        let loaded = store.load()
        XCTAssertEqual(loaded, originals)
    }

    func test_invalid_inputs_are_clamped() {
        let a = Alarm(hour: 99, minute: 99)
        XCTAssertEqual(a.hour, 23)
        XCTAssertEqual(a.minute, 59)
    }

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("PocketCoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

final class TimezoneCatalogTests: XCTestCase {
    func test_all_returns_nonempty_iana_zones() {
        let entries = TimezoneCatalog.all()
        XCTAssertFalse(entries.isEmpty)
        XCTAssertTrue(entries.contains(where: { $0.identifier == "America/Los_Angeles" }))
        XCTAssertTrue(entries.contains(where: { $0.identifier == "Europe/London" }))
    }

    func test_search_by_city() {
        let hits = TimezoneCatalog.search("london")
        XCTAssertTrue(hits.contains(where: { $0.identifier == "Europe/London" }))
    }

    func test_search_empty_query_returns_all() {
        let entries = TimezoneCatalog.all()
        XCTAssertEqual(TimezoneCatalog.search("", in: entries).count, entries.count)
    }

    func test_displayCity_replaces_underscores() {
        let entry = TimezoneEntry(identifier: "America/New_York")
        XCTAssertEqual(entry.displayCity, "New York")
        XCTAssertEqual(entry.region, "America")
    }
}

final class BedtimeEngineTests: XCTestCase {
    func test_sleepHours_within_same_day_window() {
        XCTAssertEqual(BedtimeEngine.sleepHours(bedtime: (22, 0), wake: (6, 0)), 8.0, accuracy: 1e-9)
    }

    func test_sleepHours_no_wrap_when_wake_after_bed() {
        XCTAssertEqual(BedtimeEngine.sleepHours(bedtime: (1, 30), wake: (8, 0)), 6.5, accuracy: 1e-9)
    }

    func test_winddown_inside_window() {
        XCTAssertTrue(BedtimeEngine.isWinddown(now: (21, 45), bedtime: (22, 0)))
        XCTAssertFalse(BedtimeEngine.isWinddown(now: (22, 1), bedtime: (22, 0)))
        XCTAssertFalse(BedtimeEngine.isWinddown(now: (21, 0), bedtime: (22, 0)))
    }

    func test_winddown_wraps_midnight() {
        XCTAssertTrue(BedtimeEngine.isWinddown(now: (23, 50), bedtime: (0, 10)))
        XCTAssertTrue(BedtimeEngine.isWinddown(now: (0, 5),  bedtime: (0, 10)))
    }
}
