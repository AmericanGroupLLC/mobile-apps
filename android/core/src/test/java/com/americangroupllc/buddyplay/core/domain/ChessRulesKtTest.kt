package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ChessRulesKtTest {

    private fun newGame(): Triple<ChessState, Peer, Peer> {
        val h = Peer("00000000-0000-0000-0000-000000000001", "H", Peer.Platform.IOS, 0L)
        val g = Peer("00000000-0000-0000-0000-000000000002", "G", Peer.Platform.ANDROID, 0L)
        return Triple(ChessRules.initialState(h, g), h, g)
    }

    private fun sq(f: Int, r: Int) = ChessSquare(f, r)

    private fun move(s: ChessState, from: ChessSquare, to: ChessSquare, promo: ChessPieceKind? = null) =
        ChessRules.reduce(s, ChessMove(from, to, promotion = promo)).state

    @Test
    fun pawnE2E4IsLegal() {
        val (s0, _, _) = newGame()
        val s1 = move(s0, sq(4,1), sq(4,3))
        assertThat(s1.board[sq(4,3)]).isNotNull()
        assertThat(s1.board[sq(4,1)]).isNull()
    }

    @Test(expected = GameStateReducer.Error.Illegal::class)
    fun illegalMoveThrows() {
        val (s0, _, _) = newGame()
        move(s0, sq(1,0), sq(4,4)) // knight to unreachable square
    }

    @Test
    fun scholarsMate() {
        val (s0, _, _) = newGame()
        var s = s0
        s = move(s, sq(4,1), sq(4,3))      // 1. e4
        s = move(s, sq(4,6), sq(4,4))      // 1...e5
        s = move(s, sq(5,0), sq(2,3))      // 2. Bc4
        s = move(s, sq(1,7), sq(2,5))      // 2...Nc6
        s = move(s, sq(3,0), sq(7,4))      // 3. Qh5
        s = move(s, sq(6,7), sq(5,5))      // 3...Nf6??
        val result = ChessRules.reduce(s, ChessMove(sq(7,4), sq(5,6))) // 4. Qxf7#
        assertThat(result.outcome).isInstanceOf(GameStateReducer.Outcome.Winner::class.java)
        assertThat((result.state.outcome as ChessOutcome.Checkmate).winner).isEqualTo(result.state.white)
    }

    @Test
    fun castlingKingSideIsLegalWhenPathClear() {
        val (s0, _, _) = newGame()
        var s = s0
        s = move(s, sq(4,1), sq(4,3))     // e4
        s = move(s, sq(0,6), sq(0,5))     // a6
        s = move(s, sq(6,0), sq(5,2))     // Nf3
        s = move(s, sq(0,5), sq(0,4))     // a5
        s = move(s, sq(5,0), sq(4,1))     // Be2
        s = move(s, sq(0,4), sq(0,3))     // a4
        val castle = ChessRules.reduce(s, ChessMove(sq(4,0), sq(6,0), isCastleKingSide = true)).state
        assertThat(castle.board[sq(6,0)]?.kind).isEqualTo(ChessPieceKind.KING)
        assertThat(castle.board[sq(5,0)]?.kind).isEqualTo(ChessPieceKind.ROOK)
        assertThat(castle.board[sq(4,0)]).isNull()
        assertThat(castle.board[sq(7,0)]).isNull()
    }

    @Test
    fun promotionToQueen() {
        val (_, h, g) = newGame()
        val board = HashMap<ChessSquare, ChessPiece>()
        board[sq(0,6)] = ChessPiece(ChessColor.WHITE, ChessPieceKind.PAWN)
        board[sq(4,0)] = ChessPiece(ChessColor.WHITE, ChessPieceKind.KING)
        board[sq(4,7)] = ChessPiece(ChessColor.BLACK, ChessPieceKind.KING)
        val s = ChessState(
            board = board, sideToMove = ChessColor.WHITE, white = h.id, black = g.id,
            castling = CastlingRights(false, false, false, false),
            enPassantTarget = null, halfmoveClock = 0, fullmoveNumber = 1,
            history = mutableListOf(), outcome = null,
        )
        val promoted = move(s, sq(0,6), sq(0,7), promo = ChessPieceKind.QUEEN)
        assertThat(promoted.board[sq(0,7)]?.kind).isEqualTo(ChessPieceKind.QUEEN)
    }
}
