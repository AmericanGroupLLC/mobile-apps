import XCTest
@testable import BuddyCore

final class LudoRulesTests: XCTestCase {

    private func newGame() -> (LudoState, UUID, UUID) {
        let h = Peer(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                     displayName: "H", platform: .ios, lastSeenAt: Date())
        let g = Peer(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                     displayName: "G", platform: .android, lastSeenAt: Date())
        return (LudoRules.initialState(host: h, guest: g), h.id, g.id)
    }

    func testCannotLeaveBaseWithoutSix() throws {
        let (s0, h, _) = newGame()
        XCTAssertThrowsError(
            try LudoRules.reduce(s0, input: LudoMove(player: h, diceRoll: 3, tokenIndex: 0))
        )
    }

    func testRollingSixGrantsExtraTurn() throws {
        let (s0, h, _) = newGame()
        let s1 = try LudoRules.reduce(s0, input: LudoMove(player: h, diceRoll: 6, tokenIndex: 0)).state
        XCTAssertEqual(s1.sideToMove, h, "6 → same player goes again")
        XCTAssertEqual(s1.tokens[h]![0], 0)
    }

    func testNonSixRotatesTurn() throws {
        let (s0, h, g) = newGame()
        // Host can't move (no token out + die ≠ 6) → pass.
        let s1 = try LudoRules.reduce(s0, input: LudoMove(player: h, diceRoll: 4, tokenIndex: nil)).state
        XCTAssertEqual(s1.sideToMove, g)
    }

    func testThreeConsecutiveSixesForfeitsTurn() throws {
        let (s0, h, g) = newGame()
        var s = s0
        s = try LudoRules.reduce(s, input: LudoMove(player: h, diceRoll: 6, tokenIndex: 0)).state // out
        s = try LudoRules.reduce(s, input: LudoMove(player: h, diceRoll: 6, tokenIndex: 1)).state // out
        s = try LudoRules.reduce(s, input: LudoMove(player: h, diceRoll: 6, tokenIndex: nil)).state // 3rd 6
        XCTAssertEqual(s.sideToMove, g, "3 sixes in a row → turn forfeited")
    }

    func testCaptureSendsOpponentHome() throws {
        let (s0, h, g) = newGame()
        var s = s0
        // Get guest token onto square 4 (entry 26 + 4 = 30 actually; using direct setup).
        var tokens = s.tokens
        tokens[g]![0] = 4
        s.tokens = tokens

        // Host rolls 6 to leave base, lands on entry square 0.
        s = try LudoRules.reduce(s, input: LudoMove(player: h, diceRoll: 6, tokenIndex: 0)).state
        // Now host rolls 4, advances host token from 0 to 4 — captures guest.
        s = try LudoRules.reduce(s, input: LudoMove(player: h, diceRoll: 4, tokenIndex: 0)).state
        XCTAssertEqual(s.tokens[h]![0], 4)
        XCTAssertEqual(s.tokens[g]![0], -1, "guest token should be sent home")
    }
}
