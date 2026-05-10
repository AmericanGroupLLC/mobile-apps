import XCTest
@testable import DriftCore

final class ToneClassifierTests: XCTestCase {

    private let conv = UUID()
    private let a = UUID()
    private let b = UUID()
    private func msg(_ text: String, _ at: Date, by: UUID? = nil) -> Message {
        Message(conversationId: conv, authorId: by ?? a, text: text, createdAt: at)
    }

    func testEmptyMessagesReturnsSlow() {
        XCTAssertEqual(ToneClassifier.classify(messages: []), .slow)
    }

    func testFiveMinuteGapKeepsSlow() {
        let now = Date()
        let m1 = msg("hi", now.addingTimeInterval(-5 * 3600))
        let m2 = msg("hey", now)
        XCTAssertEqual(ToneClassifier.classify(messages: [m1, m2], now: now), .slow)
    }

    func testTenMessagesInFiveMinutesIsEnergetic() {
        let now = Date()
        var msgs: [Message] = []
        for i in 0..<10 {
            msgs.append(msg("ping \(i)", now.addingTimeInterval(Double(i) * 30), by: i.isMultiple(of: 2) ? a : b))
        }
        XCTAssertEqual(ToneClassifier.classify(messages: msgs, now: now), .energetic)
    }

    func testLongAverageMessageLengthIsDeep() {
        let now = Date()
        let long = String(repeating: "x", count: 250)
        let msgs = [msg(long, now.addingTimeInterval(-60)), msg(long, now)]
        XCTAssertEqual(ToneClassifier.classify(messages: msgs, now: now), .deep)
    }

    func testMeetupKeywordTriggersMeetupReady() {
        let now = Date()
        let msgs = [msg("yeah want to grab coffee Sat?", now)]
        XCTAssertEqual(ToneClassifier.classify(messages: msgs, now: now), .meetupReady)
    }
}
