import XCTest
@testable import CardCore

final class CardKindTransitionsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000) // fixed
    private var future: Date { now.addingTimeInterval(60 * 60) }
    private var past: Date { now.addingTimeInterval(-60 * 60) }

    func testIdentityTransitionForNoteIsNoOp() {
        let card = Card(text: "hi", kind: .note, createdAt: now, updatedAt: now)
        let result = CardKindTransitions.convert(card, to: .note, now: now)
        XCTAssertEqual(result, card)
    }

    func testNoteToTaskClearsReminderAt() {
        let card = Card(text: "x", kind: .note, reminderAt: future, createdAt: now, updatedAt: now)
        let result = CardKindTransitions.convert(card, to: .task, now: now)
        XCTAssertEqual(result?.kind, .task)
        XCTAssertNil(result?.reminderAt)
    }

    func testNoteToReminderRequiresFutureDate() {
        let card = Card(text: "x", kind: .note, createdAt: now, updatedAt: now)
        XCTAssertNil(CardKindTransitions.convert(card, to: .reminder, reminderAt: nil, now: now))
        XCTAssertNil(CardKindTransitions.convert(card, to: .reminder, reminderAt: past, now: now))
        XCTAssertNil(CardKindTransitions.convert(card, to: .reminder, reminderAt: now, now: now))
        let result = CardKindTransitions.convert(card, to: .reminder, reminderAt: future, now: now)
        XCTAssertEqual(result?.kind, .reminder)
        XCTAssertEqual(result?.reminderAt, future)
    }

    func testTaskToNoteClearsCompletedAt() {
        let card = Card(text: "x", kind: .task, completedAt: now, createdAt: now, updatedAt: now)
        let result = CardKindTransitions.convert(card, to: .note, now: now)
        XCTAssertEqual(result?.kind, .note)
        XCTAssertNil(result?.completedAt)
    }

    func testReminderToTaskClearsReminderAt() {
        let card = Card(text: "x", kind: .reminder, reminderAt: future, createdAt: now, updatedAt: now)
        let result = CardKindTransitions.convert(card, to: .task, now: now)
        XCTAssertEqual(result?.kind, .task)
        XCTAssertNil(result?.reminderAt)
        XCTAssertNil(result?.completedAt)
    }

    func testToggleCompletedOnlyAffectsTasks() {
        let note = Card(text: "x", kind: .note, createdAt: now, updatedAt: now)
        XCTAssertFalse(CardKindTransitions.toggleCompleted(note, now: now).isCompleted)

        let task = Card(text: "x", kind: .task, createdAt: now, updatedAt: now)
        let toggled = CardKindTransitions.toggleCompleted(task, now: now)
        XCTAssertTrue(toggled.isCompleted)
        let untoggled = CardKindTransitions.toggleCompleted(toggled, now: now)
        XCTAssertFalse(untoggled.isCompleted)
    }

    func testConvertUpdatesUpdatedAt() {
        let card = Card(text: "x", kind: .note, createdAt: now, updatedAt: now)
        let later = now.addingTimeInterval(60)
        let result = CardKindTransitions.convert(card, to: .task, now: later)
        XCTAssertEqual(result?.updatedAt, later)
    }
}
