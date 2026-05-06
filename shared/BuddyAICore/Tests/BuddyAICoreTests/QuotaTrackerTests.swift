import XCTest
@testable import BuddyAICore

final class QuotaTrackerTests: XCTestCase {

    private let pid = UUID()

    func testFreeTierAllows10ChatsThenBlocks() {
        var s = QuotaState(profileId: pid, day: "2026-05-06")
        for _ in 0..<10 {
            XCTAssertTrue(QuotaTracker.decide(state: s, proUnlocked: false).allowed)
            s = QuotaTracker.reduce(state: s, event: .chatStarted, proUnlocked: false)
        }
        XCTAssertFalse(QuotaTracker.decide(state: s, proUnlocked: false).allowed)
    }

    func testAdWatchGrants5MoreChats() {
        var s = QuotaState(profileId: pid, day: "2026-05-06", chatsUsed: 10)
        XCTAssertFalse(QuotaTracker.decide(state: s, proUnlocked: false).allowed)
        s = QuotaTracker.reduce(state: s, event: .adWatched, proUnlocked: false)
        XCTAssertEqual(QuotaTracker.decide(state: s, proUnlocked: false).chatsRemaining, 5)
    }

    func testMidnightRolloverReset() {
        var s = QuotaState(profileId: pid, day: "2026-05-06", chatsUsed: 10, adUnlocks: 1)
        s = QuotaTracker.reduce(state: s, event: .rollover(toDay: "2026-05-07"), proUnlocked: false)
        XCTAssertEqual(s.chatsUsed, 0)
        XCTAssertEqual(s.adUnlocks, 0)
        XCTAssertEqual(s.day, "2026-05-07")
    }

    func testProEntitlementBypassesQuota() {
        var s = QuotaState(profileId: pid, day: "2026-05-06", chatsUsed: 1_000_000)
        let d = QuotaTracker.decide(state: s, proUnlocked: true)
        XCTAssertTrue(d.allowed)
        XCTAssertFalse(d.canWatchAd)
        s = QuotaTracker.reduce(state: s, event: .chatStarted, proUnlocked: true)
        XCTAssertEqual(s.chatsUsed, 1_000_000)
    }

    func testDayStringFormatStable() {
        let date = Date(timeIntervalSince1970: 1_762_392_000)   // ~2025-11-06 UTC
        let day = QuotaState.dayString(for: date, calendar: Calendar(identifier: .gregorian))
        XCTAssertEqual(day.count, 10)
        XCTAssertEqual(day[day.index(day.startIndex, offsetBy: 4)], "-")
    }
}
