import XCTest
@testable import BuddyCore

final class ChessRulesTests: XCTestCase {

    private func newGame() -> (ChessState, Peer, Peer) {
        let h = Peer(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                     displayName: "H", platform: .ios, lastSeenAt: Date())
        let g = Peer(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                     displayName: "G", platform: .android, lastSeenAt: Date())
        return (ChessRules.initialState(host: h, guest: g), h, g)
    }

    private func sq(_ f: Int, _ r: Int) -> ChessSquare { ChessSquare(file: f, rank: r)! }

    private func move(_ s: ChessState, from f: ChessSquare, to t: ChessSquare, promotion: ChessPiece.Kind? = nil) throws -> ChessState {
        try ChessRules.reduce(s, input: ChessMove(from: f, to: t, promotion: promotion)).state
    }

    func testPawnE2E4IsLegal() throws {
        let (s0, _, _) = newGame()
        let s1 = try move(s0, from: sq(4,1), to: sq(4,3))
        XCTAssertNotNil(s1.board[sq(4,3)])
        XCTAssertNil(s1.board[sq(4,1)])
    }

    func testIllegalMoveRaises() {
        let (s0, _, _) = newGame()
        // Move a knight to a square it can't reach.
        XCTAssertThrowsError(try move(s0, from: sq(1,0), to: sq(4,4)))
    }

    func testScholarsMate() throws {
        // 1.e4 e5 2.Bc4 Nc6 3.Qh5 Nf6?? 4.Qxf7# is mate.
        let (s0, _, _) = newGame()
        var s = s0
        s = try move(s, from: sq(4,1), to: sq(4,3))      // 1. e4
        s = try move(s, from: sq(4,6), to: sq(4,4))      // 1...e5
        s = try move(s, from: sq(5,0), to: sq(2,3))      // 2. Bc4
        s = try move(s, from: sq(1,7), to: sq(2,5))      // 2...Nc6
        s = try move(s, from: sq(3,0), to: sq(7,4))      // 3. Qh5
        s = try move(s, from: sq(6,7), to: sq(5,5))      // 3...Nf6??
        let result = try ChessRules.reduce(s, input: ChessMove(from: sq(7,4), to: sq(5,6))) // 4. Qxf7#
        if case .winner(let id) = result.outcome {
            XCTAssertEqual(id, result.state.white)
        } else {
            XCTFail("expected mate, got \(String(describing: result.outcome))")
        }
        if case .checkmate = result.state.outcome {} else {
            XCTFail("state outcome should be .checkmate")
        }
    }

    func testCastlingKingSideIsLegalWhenPathClear() throws {
        // Build position: e2 pawn moved to e4, knight g1→f3, bishop f1→e2.
        let (s0, _, _) = newGame()
        var s = s0
        s = try move(s, from: sq(4,1), to: sq(4,3))     // 1.e4
        s = try move(s, from: sq(0,6), to: sq(0,5))     // 1...a6 (mute)
        s = try move(s, from: sq(6,0), to: sq(5,2))     // 2.Nf3
        s = try move(s, from: sq(0,5), to: sq(0,4))     // 2...a5
        s = try move(s, from: sq(5,0), to: sq(4,1))     // 3.Be2
        s = try move(s, from: sq(0,4), to: sq(0,3))     // 3...a4
        // 4.O-O
        let castle = try ChessRules.reduce(s, input: ChessMove(from: sq(4,0), to: sq(6,0), isCastleKingSide: true))
        XCTAssertEqual(castle.state.board[sq(6,0)]?.kind, .king)
        XCTAssertEqual(castle.state.board[sq(5,0)]?.kind, .rook)
        XCTAssertNil(castle.state.board[sq(4,0)])
        XCTAssertNil(castle.state.board[sq(7,0)])
    }

    func testPromotionToQueen() throws {
        // Build a minimal position: white pawn on a7 ready to promote to a8.
        let (_, h, g) = newGame()
        var board: [ChessSquare: ChessPiece] = [:]
        board[sq(0,6)] = ChessPiece(color: .white, kind: .pawn)
        board[sq(4,0)] = ChessPiece(color: .white, kind: .king)
        board[sq(4,7)] = ChessPiece(color: .black, kind: .king)
        let s = ChessState(
            board: board, sideToMove: .white, white: h.id, black: g.id,
            castling: .init(whiteKing: false, whiteQueen: false, blackKing: false, blackQueen: false),
            enPassantTarget: nil, halfmoveClock: 0, fullmoveNumber: 1, history: [], outcome: nil
        )
        let promoted = try ChessRules.reduce(s, input: ChessMove(from: sq(0,6), to: sq(0,7), promotion: .queen)).state
        XCTAssertEqual(promoted.board[sq(0,7)]?.kind, .queen)
    }
}
