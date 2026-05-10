import XCTest
@testable import DriftCore

final class ReplyPromptBuilderTests: XCTestCase {

    private let conv = UUID()
    private let viewer = Profile(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        displayName: "Sara",
        intent: .dating,
        vibeTags: ["coffee","books"]
    )
    private let target = Profile(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        displayName: "Maya",
        intent: .serious,
        vibeTags: ["hiking","music"]
    )

    func testSystemContainsStrictJsonContract() {
        let out = ReplyPromptBuilder.build(.init(viewer: viewer, target: target, lastMessages: [], tone: .slow))
        XCTAssertTrue(out.system.contains("strict JSON"))
        XCTAssertTrue(out.system.contains("\"casual\""))
        XCTAssertTrue(out.system.contains("private location"))
    }

    func testUserSectionIncludesBothProfilesAndVibes() {
        let out = ReplyPromptBuilder.build(.init(viewer: viewer, target: target, lastMessages: [], tone: .slow))
        XCTAssertTrue(out.user.contains("Sara"))
        XCTAssertTrue(out.user.contains("Maya"))
        XCTAssertTrue(out.user.contains("dating"))
        XCTAssertTrue(out.user.contains("serious"))
        XCTAssertTrue(out.user.contains("coffee"))
        XCTAssertTrue(out.user.contains("hiking"))
    }

    func testMessagesAppearInChronologicalOrder() {
        let now = Date()
        let m1 = Message(conversationId: conv, authorId: viewer.id, text: "first", createdAt: now.addingTimeInterval(-120))
        let m2 = Message(conversationId: conv, authorId: target.id, text: "second", createdAt: now.addingTimeInterval(-60))
        let m3 = Message(conversationId: conv, authorId: viewer.id, text: "third", createdAt: now)
        let out = ReplyPromptBuilder.build(.init(viewer: viewer, target: target, lastMessages: [m1, m2, m3], tone: .energetic))
        let iFirst  = out.user.range(of: "first")!.lowerBound
        let iSecond = out.user.range(of: "second")!.lowerBound
        let iThird  = out.user.range(of: "third")!.lowerBound
        XCTAssertLessThan(iFirst, iSecond)
        XCTAssertLessThan(iSecond, iThird)
    }

    func testToneClauseIncludedForMeetupReady() {
        let out = ReplyPromptBuilder.build(.init(viewer: viewer, target: target, lastMessages: [], tone: .meetupReady))
        XCTAssertTrue(out.system.contains("public-place"))
    }

    func testGoldenSnapshotForFixedInputs() {
        // Stable signal that the wire-prompt doesn't drift unintentionally.
        let out = ReplyPromptBuilder.build(.init(viewer: viewer, target: target, lastMessages: [], tone: .slow))
        XCTAssertEqual(
            out.user,
            """
            Person A: Sara (intent: dating, vibes: coffee, books)
            Person B: Maya (intent: serious, vibes: hiking, music)

            Last messages (oldest → newest):
            (no messages yet — these are opener suggestions)
            """
        )
    }
}
