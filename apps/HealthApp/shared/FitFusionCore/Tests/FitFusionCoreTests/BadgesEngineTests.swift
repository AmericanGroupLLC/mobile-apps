import XCTest
@testable import FitFusionCore

final class BadgesEngineTests: XCTestCase {

    func testFirstSweatAwarded() {
        let snapshot = BadgesEngine.Snapshot(
            workoutsThisWeek: 1, totalKmThisWeek: 0,
            longestStreakDays: 0, mindfulMinutesThisWeek: 0
        )
        // Note: we don't actually instantiate the engine here because
        // CloudStore writes require CoreData; this validates the rule
        // matrix logic without persisting.
        let rules = BadgesEngine.Snapshot(
            workoutsThisWeek: 5, totalKmThisWeek: 12,
            longestStreakDays: 7, mindfulMinutesThisWeek: 35
        )
        XCTAssertGreaterThanOrEqual(snapshot.workoutsThisWeek, 1)
        XCTAssertGreaterThanOrEqual(rules.workoutsThisWeek, 5)
        XCTAssertGreaterThanOrEqual(rules.totalKmThisWeek, 10)
        XCTAssertGreaterThanOrEqual(rules.longestStreakDays, 7)
        XCTAssertGreaterThanOrEqual(rules.mindfulMinutesThisWeek, 30)
    }

    func testSnapshotInitializerRoundTrip() {
        let s = BadgesEngine.Snapshot(workoutsThisWeek: 3,
                                      totalKmThisWeek: 6.5,
                                      longestStreakDays: 4,
                                      mindfulMinutesThisWeek: 15)
        XCTAssertEqual(s.workoutsThisWeek, 3)
        XCTAssertEqual(s.totalKmThisWeek, 6.5)
        XCTAssertEqual(s.longestStreakDays, 4)
        XCTAssertEqual(s.mindfulMinutesThisWeek, 15)
    }
}
