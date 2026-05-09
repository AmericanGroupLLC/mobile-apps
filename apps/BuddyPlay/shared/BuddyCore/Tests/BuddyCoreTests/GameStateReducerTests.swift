import XCTest
@testable import BuddyCore

final class GameStateReducerTests: XCTestCase {

    private func mkPeers() -> (Peer, Peer) {
        let h = Peer(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Host", platform: .ios, lastSeenAt: Date()
        )
        let g = Peer(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            displayName: "Guest", platform: .android, lastSeenAt: Date()
        )
        return (h, g)
    }

    func testChessReducerRotatesTurn() throws {
        let (h, g) = mkPeers()
        let s0 = ChessRules.initialState(host: h, guest: g)
        XCTAssertEqual(ChessRules.currentTurn(s0), h.id)
        // Move pawn e2-e4
        let move = ChessMove(from: ChessSquare(file: 4, rank: 1)!, to: ChessSquare(file: 4, rank: 3)!)
        let step = try ChessRules.reduce(s0, input: move)
        XCTAssertEqual(ChessRules.currentTurn(step.state), g.id)
        XCTAssertNil(step.outcome)
    }

    func testLudoReducerRotatesTurnUnlessSix() throws {
        let (h, g) = mkPeers()
        let s0 = LudoRules.initialState(host: h, guest: g)
        // Roll a 1 (no token can move out, must pass).
        let pass = LudoMove(player: h.id, diceRoll: 1, tokenIndex: nil)
        let s1 = try LudoRules.reduce(s0, input: pass).state
        XCTAssertEqual(LudoRules.currentTurn(s1), g.id)
        // Now host rolls a 6 — moves a token out, gets another turn.
        let s2 = try LudoRules.reduce(s1, input: LudoMove(player: g.id, diceRoll: 6, tokenIndex: 0)).state
        XCTAssertEqual(LudoRules.currentTurn(s2), g.id, "rolling 6 should grant extra turn")
    }

    func testRacerReducerAdvancesTickCount() throws {
        let (h, g) = mkPeers()
        let s0 = RacerPhysics.initialState(host: h, guest: g)
        XCTAssertEqual(s0.tickCount, 0)
        let input = RacerInput(player: h.id, throttle: 1.0, brake: 0, steering: 0)
        let s1 = try RacerPhysics.reduce(s0, input: input).state
        XCTAssertEqual(s1.tickCount, 1)
        // Real-time games have no current turn.
        XCTAssertNil(RacerPhysics.currentTurn(s1))
    }
}
