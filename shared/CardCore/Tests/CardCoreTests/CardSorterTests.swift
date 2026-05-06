import XCTest
@testable import CardCore

final class CardSorterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testEmptyInputReturnsEmpty() {
        XCTAssertTrue(CardSorter.sort([], now: now).isEmpty)
    }

    func testCompletedTasksGoToBottom() {
        let openNote = Card(text: "open", kind: .note,
                            createdAt: now, updatedAt: now.addingTimeInterval(-60))
        let doneTask = Card(text: "done", kind: .task,
                            completedAt: now.addingTimeInterval(-30),
                            createdAt: now, updatedAt: now)
        let result = CardSorter.sort([doneTask, openNote], now: now)
        XCTAssertEqual(result.first?.id, openNote.id)
        XCTAssertEqual(result.last?.id, doneTask.id)
    }

    func testDueSoonRemindersPinnedToTop() {
        let dueIn1h = Card(text: "soon", kind: .reminder,
                           reminderAt: now.addingTimeInterval(3600),
                           createdAt: now, updatedAt: now.addingTimeInterval(-1000))
        let recentNote = Card(text: "recent", kind: .note,
                              createdAt: now, updatedAt: now)
        let result = CardSorter.sort([recentNote, dueIn1h], now: now)
        XCTAssertEqual(result.first?.id, dueIn1h.id)
    }

    func testRemindersBeyond24hAreNotPinned() {
        let far = Card(text: "later", kind: .reminder,
                       reminderAt: now.addingTimeInterval(48 * 3600),
                       createdAt: now, updatedAt: now.addingTimeInterval(-1000))
        let recentNote = Card(text: "recent", kind: .note,
                              createdAt: now, updatedAt: now)
        let result = CardSorter.sort([far, recentNote], now: now)
        XCTAssertEqual(result.first?.id, recentNote.id)
    }

    func testMiddleSortedByUpdatedAtDescending() {
        let older = Card(text: "older", kind: .note,
                         createdAt: now, updatedAt: now.addingTimeInterval(-200))
        let newer = Card(text: "newer", kind: .note,
                         createdAt: now, updatedAt: now.addingTimeInterval(-50))
        let result = CardSorter.sort([older, newer], now: now)
        XCTAssertEqual(result.map { $0.text }, ["newer", "older"])
    }

    func testCompositeOrdering() {
        let dueSoon = Card(text: "due-soon", kind: .reminder,
                           reminderAt: now.addingTimeInterval(60 * 30),
                           createdAt: now, updatedAt: now.addingTimeInterval(-5000))
        let recent  = Card(text: "recent",   kind: .note,
                           createdAt: now, updatedAt: now)
        let done    = Card(text: "done",     kind: .task,
                           completedAt: now, createdAt: now, updatedAt: now)
        let result = CardSorter.sort([done, recent, dueSoon], now: now)
        XCTAssertEqual(result.map { $0.text }, ["due-soon", "recent", "done"])
    }
}
