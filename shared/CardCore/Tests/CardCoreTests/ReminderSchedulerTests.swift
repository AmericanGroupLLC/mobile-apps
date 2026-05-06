import XCTest
@testable import CardCore

final class ReminderSchedulerTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testNextFireTimeReturnsFutureUnchanged() {
        let future = now.addingTimeInterval(120)
        XCTAssertEqual(ReminderScheduler.nextFireTime(for: future, now: now), future)
    }

    func testNextFireTimeReturnsNilForPast() {
        let past = now.addingTimeInterval(-1)
        XCTAssertNil(ReminderScheduler.nextFireTime(for: past, now: now))
    }

    func testNextFireTimeReturnsNilForNow() {
        XCTAssertNil(ReminderScheduler.nextFireTime(for: now, now: now))
    }

    func testGroupByMinuteCollapsesIdenticalMinutes() {
        let cal = Calendar(identifier: .gregorian)
        let minute = cal.date(from: DateComponents(year: 2026, month: 5, day: 6, hour: 9, minute: 30))!
        let a = Card(text: "a", kind: .reminder, reminderAt: minute.addingTimeInterval(5),  createdAt: now, updatedAt: now)
        let b = Card(text: "b", kind: .reminder, reminderAt: minute.addingTimeInterval(40), createdAt: now, updatedAt: now)
        let c = Card(text: "c", kind: .reminder, reminderAt: minute.addingTimeInterval(60 * 60), createdAt: now, updatedAt: now)

        let buckets = ReminderScheduler.groupByMinute([a, b, c], calendar: cal, now: now)
        XCTAssertEqual(buckets.count, 2)
        XCTAssertEqual(buckets[minute], 2)
    }

    func testGroupByMinuteIgnoresPastReminders() {
        let cal = Calendar(identifier: .gregorian)
        let past = now.addingTimeInterval(-3600)
        let card = Card(text: "x", kind: .reminder, reminderAt: past, createdAt: now, updatedAt: now)
        XCTAssertTrue(ReminderScheduler.groupByMinute([card], calendar: cal, now: now).isEmpty)
    }

    func testGroupByMinuteIgnoresNonReminderKinds() {
        let cal = Calendar(identifier: .gregorian)
        let future = now.addingTimeInterval(60)
        let note = Card(text: "x", kind: .note, reminderAt: future, createdAt: now, updatedAt: now)
        let task = Card(text: "y", kind: .task, reminderAt: future, createdAt: now, updatedAt: now)
        XCTAssertTrue(ReminderScheduler.groupByMinute([note, task], calendar: cal, now: now).isEmpty)
    }

    /// DST spring-forward: 2:30 AM does not exist on the second-Sunday of March
    /// in America/Los_Angeles. The scheduler should still return *some*
    /// future Date (Calendar resolves the gap) and never crash.
    func testNextFireTimeAcrossDSTBoundary() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let preDST = cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 30))!
        let target = preDST.addingTimeInterval(60 * 60) // crosses spring-forward
        XCTAssertEqual(ReminderScheduler.nextFireTime(for: target, now: preDST), target)
    }
}
