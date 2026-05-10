package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import kotlinx.serialization.Serializable

/**
 * Pure chess rules implementation. Operates over [ChessState] with [ChessMove]
 * inputs. Implements full move legality including:
 *   - castling (king-side + queen-side, blocked through check)
 *   - en passant (captured pawn removed correctly)
 *   - promotion (queen, rook, bishop, knight)
 *   - check / mate / stalemate detection
 *   - 50-move rule (basic)
 */
object ChessRules : GameStateReducer<ChessState, ChessMove> {

    override fun initialState(host: Peer, guest: Peer): ChessState =
        ChessState(
            board = ChessState.startingBoard(),
            sideToMove = ChessColor.WHITE,
            white = host.id,
            black = guest.id,
            castling = CastlingRights(true, true, true, true),
            enPassantTarget = null,
            halfmoveClock = 0,
            fullmoveNumber = 1,
            history = mutableListOf(),
            outcome = null,
        )

    override fun reduce(state: ChessState, input: ChessMove): GameStateReducer.Step<ChessState> {
        if (state.outcome != null) throw GameStateReducer.Error.GameOver
        val piece = state.board[input.from] ?: throw GameStateReducer.Error.Illegal("no piece on ${input.from}")
        if (piece.color != state.sideToMove) throw GameStateReducer.Error.WrongTurn
        val legal = legalMoves(state, piece.color)
        if (input !in legal) throw GameStateReducer.Error.Illegal("$input is not legal")

        var s = state.copy(board = HashMap(state.board), history = ArrayList(state.history))
        applyMoveInPlace(s, input, piece)

        s = s.copy(sideToMove = s.sideToMove.opposite)
        if (s.sideToMove == ChessColor.WHITE) s = s.copy(fullmoveNumber = s.fullmoveNumber + 1)

        val theirMoves = legalMoves(s, s.sideToMove)
        if (theirMoves.isEmpty()) {
            return if (isInCheck(s, s.sideToMove)) {
                val winnerColor = s.sideToMove.opposite
                val winnerId = if (winnerColor == ChessColor.WHITE) s.white else s.black
                val final = s.copy(outcome = ChessOutcome.Checkmate(winnerId))
                GameStateReducer.Step(final, GameStateReducer.Outcome.Winner(winnerId))
            } else {
                val final = s.copy(outcome = ChessOutcome.Stalemate)
                GameStateReducer.Step(final, GameStateReducer.Outcome.Draw)
            }
        }
        if (s.halfmoveClock >= 100) {
            val final = s.copy(outcome = ChessOutcome.FiftyMoveRule)
            return GameStateReducer.Step(final, GameStateReducer.Outcome.Draw)
        }
        return GameStateReducer.Step(s, null)
    }

    override fun isFinal(state: ChessState): Boolean = state.outcome != null

    override fun currentTurn(state: ChessState): String? =
        if (state.outcome != null) null
        else if (state.sideToMove == ChessColor.WHITE) state.white else state.black

    // MARK: - Public helpers

    fun legalMoves(state: ChessState, color: ChessColor): Set<ChessMove> {
        val out = HashSet<ChessMove>()
        for (sq in ChessSquare.all) {
            val p = state.board[sq] ?: continue
            if (p.color != color) continue
            for (m in pseudoLegalMoves(state, sq)) {
                if (!leavesOwnKingInCheck(state, m, color)) out += m
            }
        }
        return out
    }

    fun isInCheck(state: ChessState, color: ChessColor): Boolean {
        val king = state.kingSquare(color) ?: return false
        return isAttacked(state.board, king, color.opposite)
    }

    // MARK: - Pseudo-legal generation

    private fun pseudoLegalMoves(state: ChessState, sq: ChessSquare): List<ChessMove> {
        val piece = state.board[sq] ?: return emptyList()
        val out = mutableListOf<ChessMove>()
        when (piece.kind) {
            ChessPieceKind.PAWN   -> pawnMoves(state, sq, piece, out)
            ChessPieceKind.KNIGHT -> stepperMoves(state.board, sq, piece, knightDeltas, out)
            ChessPieceKind.BISHOP -> sliderMoves(state.board, sq, piece, bishopDeltas, out)
            ChessPieceKind.ROOK   -> sliderMoves(state.board, sq, piece, rookDeltas, out)
            ChessPieceKind.QUEEN  -> {
                sliderMoves(state.board, sq, piece, bishopDeltas, out)
                sliderMoves(state.board, sq, piece, rookDeltas, out)
            }
            ChessPieceKind.KING -> {
                stepperMoves(state.board, sq, piece, kingDeltas, out)
                castlingMoves(state, sq, piece, out)
            }
        }
        return out
    }

    private fun pawnMoves(state: ChessState, sq: ChessSquare, piece: ChessPiece, out: MutableList<ChessMove>) {
        val dir = if (piece.color == ChessColor.WHITE) 1 else -1
        val startRank = if (piece.color == ChessColor.WHITE) 1 else 6
        val promoRank = if (piece.color == ChessColor.WHITE) 7 else 0

        val f1 = ChessSquare.of(sq.file, sq.rank + dir)
        if (f1 != null && state.board[f1] == null) {
            if (f1.rank == promoRank) {
                listOf(ChessPieceKind.QUEEN, ChessPieceKind.ROOK, ChessPieceKind.BISHOP, ChessPieceKind.KNIGHT)
                    .forEach { out += ChessMove(sq, f1, promotion = it) }
            } else {
                out += ChessMove(sq, f1)
            }
            if (sq.rank == startRank) {
                val f2 = ChessSquare.of(sq.file, sq.rank + 2 * dir)
                if (f2 != null && state.board[f2] == null) out += ChessMove(sq, f2)
            }
        }
        for (df in intArrayOf(-1, 1)) {
            val cap = ChessSquare.of(sq.file + df, sq.rank + dir) ?: continue
            val target = state.board[cap]
            if (target != null && target.color != piece.color) {
                if (cap.rank == promoRank) {
                    listOf(ChessPieceKind.QUEEN, ChessPieceKind.ROOK, ChessPieceKind.BISHOP, ChessPieceKind.KNIGHT)
                        .forEach { out += ChessMove(sq, cap, promotion = it) }
                } else {
                    out += ChessMove(sq, cap)
                }
            } else if (cap == state.enPassantTarget) {
                out += ChessMove(sq, cap, isEnPassant = true)
            }
        }
    }

    private fun stepperMoves(board: Map<ChessSquare, ChessPiece>, sq: ChessSquare, piece: ChessPiece, deltas: List<IntArray>, out: MutableList<ChessMove>) {
        for (d in deltas) {
            val to = ChessSquare.of(sq.file + d[0], sq.rank + d[1]) ?: continue
            val tgt = board[to]
            if (tgt != null && tgt.color == piece.color) continue
            out += ChessMove(sq, to)
        }
    }

    private fun sliderMoves(board: Map<ChessSquare, ChessPiece>, sq: ChessSquare, piece: ChessPiece, deltas: List<IntArray>, out: MutableList<ChessMove>) {
        for (d in deltas) {
            var f = sq.file + d[0]; var r = sq.rank + d[1]
            while (true) {
                val to = ChessSquare.of(f, r) ?: break
                val tgt = board[to]
                if (tgt != null) {
                    if (tgt.color != piece.color) out += ChessMove(sq, to)
                    break
                }
                out += ChessMove(sq, to)
                f += d[0]; r += d[1]
            }
        }
    }

    private fun castlingMoves(state: ChessState, sq: ChessSquare, piece: ChessPiece, out: MutableList<ChessMove>) {
        val homeRank = if (piece.color == ChessColor.WHITE) 0 else 7
        if (sq != ChessSquare.of(4, homeRank)) return
        if (isInCheck(state, piece.color)) return

        val king = if (piece.color == ChessColor.WHITE) state.castling.whiteKing else state.castling.blackKing
        val queen = if (piece.color == ChessColor.WHITE) state.castling.whiteQueen else state.castling.blackQueen

        if (king
            && state.board[ChessSquare.of(5, homeRank)!!] == null
            && state.board[ChessSquare.of(6, homeRank)!!] == null
            && !isAttacked(state.board, ChessSquare.of(5, homeRank)!!, piece.color.opposite)
            && !isAttacked(state.board, ChessSquare.of(6, homeRank)!!, piece.color.opposite)) {
            out += ChessMove(sq, ChessSquare.of(6, homeRank)!!, isCastleKingSide = true)
        }
        if (queen
            && state.board[ChessSquare.of(3, homeRank)!!] == null
            && state.board[ChessSquare.of(2, homeRank)!!] == null
            && state.board[ChessSquare.of(1, homeRank)!!] == null
            && !isAttacked(state.board, ChessSquare.of(3, homeRank)!!, piece.color.opposite)
            && !isAttacked(state.board, ChessSquare.of(2, homeRank)!!, piece.color.opposite)) {
            out += ChessMove(sq, ChessSquare.of(2, homeRank)!!, isCastleQueenSide = true)
        }
    }

    // MARK: - Apply

    private fun applyMoveInPlace(s: ChessState, move: ChessMove, movingPiece: ChessPiece) {
        val board = s.board as MutableMap<ChessSquare, ChessPiece?>
        var captured = board[move.to] != null

        if (move.isEnPassant) {
            val capSq = ChessSquare.of(move.to.file, move.from.rank)!!
            board.remove(capSq)
            captured = true
        }
        if (move.isCastleKingSide) {
            val r = move.from.rank
            board[ChessSquare.of(5, r)!!] = board[ChessSquare.of(7, r)!!]
            board.remove(ChessSquare.of(7, r)!!)
        } else if (move.isCastleQueenSide) {
            val r = move.from.rank
            board[ChessSquare.of(3, r)!!] = board[ChessSquare.of(0, r)!!]
            board.remove(ChessSquare.of(0, r)!!)
        }

        val landing = if (move.promotion != null) ChessPiece(movingPiece.color, move.promotion) else movingPiece
        board.remove(move.from)
        board[move.to] = landing

        var c = s.castling
        when (movingPiece.kind) {
            ChessPieceKind.KING -> c = if (movingPiece.color == ChessColor.WHITE) c.copy(whiteKing = false, whiteQueen = false) else c.copy(blackKing = false, blackQueen = false)
            ChessPieceKind.ROOK -> {
                if (move.from == ChessSquare.of(0, 0)) c = c.copy(whiteQueen = false)
                if (move.from == ChessSquare.of(7, 0)) c = c.copy(whiteKing  = false)
                if (move.from == ChessSquare.of(0, 7)) c = c.copy(blackQueen = false)
                if (move.from == ChessSquare.of(7, 7)) c = c.copy(blackKing  = false)
            }
            else -> Unit
        }
        if (move.to == ChessSquare.of(0, 0)) c = c.copy(whiteQueen = false)
        if (move.to == ChessSquare.of(7, 0)) c = c.copy(whiteKing  = false)
        if (move.to == ChessSquare.of(0, 7)) c = c.copy(blackQueen = false)
        if (move.to == ChessSquare.of(7, 7)) c = c.copy(blackKing  = false)

        var ep: ChessSquare? = null
        if (movingPiece.kind == ChessPieceKind.PAWN && Math.abs(move.to.rank - move.from.rank) == 2) {
            ep = ChessSquare.of(move.from.file, (move.from.rank + move.to.rank) / 2)
        }
        var hm = s.halfmoveClock + 1
        if (movingPiece.kind == ChessPieceKind.PAWN || captured) hm = 0

        s.castling = c
        s.enPassantTarget = ep
        s.halfmoveClock = hm
        (s.history as MutableList<ChessMove>).add(move)
    }

    private fun leavesOwnKingInCheck(state: ChessState, move: ChessMove, color: ChessColor): Boolean {
        val piece = state.board[move.from] ?: return false
        val probe = state.copy(board = HashMap(state.board), history = ArrayList(state.history))
        applyMoveInPlace(probe, move, piece)
        return isInCheck(probe, color)
    }

    // MARK: - Attack detection

    private fun isAttacked(board: Map<ChessSquare, ChessPiece>, square: ChessSquare, by: ChessColor): Boolean {
        val dir = if (by == ChessColor.WHITE) 1 else -1
        for (df in intArrayOf(-1, 1)) {
            val from = ChessSquare.of(square.file + df, square.rank - dir)
            val p = from?.let { board[it] }
            if (p != null && p.color == by && p.kind == ChessPieceKind.PAWN) return true
        }
        for (d in knightDeltas) {
            val from = ChessSquare.of(square.file + d[0], square.rank + d[1])
            val p = from?.let { board[it] }
            if (p != null && p.color == by && p.kind == ChessPieceKind.KNIGHT) return true
        }
        for (d in kingDeltas) {
            val from = ChessSquare.of(square.file + d[0], square.rank + d[1])
            val p = from?.let { board[it] }
            if (p != null && p.color == by && p.kind == ChessPieceKind.KING) return true
        }
        for (d in bishopDeltas) {
            var f = square.file + d[0]; var r = square.rank + d[1]
            while (true) {
                val from = ChessSquare.of(f, r) ?: break
                val p = board[from]
                if (p != null) {
                    if (p.color == by && (p.kind == ChessPieceKind.BISHOP || p.kind == ChessPieceKind.QUEEN)) return true
                    break
                }
                f += d[0]; r += d[1]
            }
        }
        for (d in rookDeltas) {
            var f = square.file + d[0]; var r = square.rank + d[1]
            while (true) {
                val from = ChessSquare.of(f, r) ?: break
                val p = board[from]
                if (p != null) {
                    if (p.color == by && (p.kind == ChessPieceKind.ROOK || p.kind == ChessPieceKind.QUEEN)) return true
                    break
                }
                f += d[0]; r += d[1]
            }
        }
        return false
    }

    private val knightDeltas = listOf(intArrayOf(1,2),intArrayOf(2,1),intArrayOf(-1,2),intArrayOf(-2,1),intArrayOf(1,-2),intArrayOf(2,-1),intArrayOf(-1,-2),intArrayOf(-2,-1))
    private val bishopDeltas = listOf(intArrayOf(1,1),intArrayOf(1,-1),intArrayOf(-1,1),intArrayOf(-1,-1))
    private val rookDeltas   = listOf(intArrayOf(1,0),intArrayOf(-1,0),intArrayOf(0,1),intArrayOf(0,-1))
    private val kingDeltas   = bishopDeltas + rookDeltas
}

// MARK: - Types

@Serializable
enum class ChessColor {
    WHITE, BLACK;
    val opposite: ChessColor get() = if (this == WHITE) BLACK else WHITE
}

@Serializable
enum class ChessPieceKind { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }

@Serializable
data class ChessPiece(val color: ChessColor, val kind: ChessPieceKind)

@Serializable
data class ChessSquare(val file: Int, val rank: Int) {
    override fun toString() = "${"abcdefgh"[file]}${rank + 1}"

    companion object {
        fun of(file: Int, rank: Int): ChessSquare? =
            if (file in 0..7 && rank in 0..7) ChessSquare(file, rank) else null

        val all: List<ChessSquare> = (0..7).flatMap { f -> (0..7).map { r -> ChessSquare(f, r) } }
    }
}

@Serializable
data class ChessMove(
    val from: ChessSquare,
    val to: ChessSquare,
    val promotion: ChessPieceKind? = null,
    val isEnPassant: Boolean = false,
    val isCastleKingSide: Boolean = false,
    val isCastleQueenSide: Boolean = false,
)

@Serializable
data class CastlingRights(
    val whiteKing: Boolean,
    val whiteQueen: Boolean,
    val blackKing: Boolean,
    val blackQueen: Boolean,
)

@Serializable
sealed class ChessOutcome {
    @Serializable data class Checkmate(val winner: String) : ChessOutcome()
    @Serializable object Stalemate : ChessOutcome()
    @Serializable object FiftyMoveRule : ChessOutcome()
    @Serializable object ThreefoldRepetition : ChessOutcome()
    @Serializable data class Resignation(val loser: String) : ChessOutcome()
}

@Serializable
data class ChessState(
    val board: MutableMap<ChessSquare, ChessPiece>,
    var sideToMove: ChessColor,
    val white: String,
    val black: String,
    var castling: CastlingRights,
    var enPassantTarget: ChessSquare?,
    var halfmoveClock: Int,
    var fullmoveNumber: Int,
    val history: MutableList<ChessMove>,
    var outcome: ChessOutcome?,
) {
    fun kingSquare(color: ChessColor): ChessSquare? {
        for (sq in ChessSquare.all) {
            val p = board[sq]
            if (p != null && p.color == color && p.kind == ChessPieceKind.KING) return sq
        }
        return null
    }

    companion object {
        fun startingBoard(): MutableMap<ChessSquare, ChessPiece> {
            val backRank = listOf(
                ChessPieceKind.ROOK, ChessPieceKind.KNIGHT, ChessPieceKind.BISHOP, ChessPieceKind.QUEEN,
                ChessPieceKind.KING, ChessPieceKind.BISHOP, ChessPieceKind.KNIGHT, ChessPieceKind.ROOK
            )
            val b = HashMap<ChessSquare, ChessPiece>()
            for (f in 0..7) {
                b[ChessSquare(f, 0)] = ChessPiece(ChessColor.WHITE, backRank[f])
                b[ChessSquare(f, 1)] = ChessPiece(ChessColor.WHITE, ChessPieceKind.PAWN)
                b[ChessSquare(f, 6)] = ChessPiece(ChessColor.BLACK, ChessPieceKind.PAWN)
                b[ChessSquare(f, 7)] = ChessPiece(ChessColor.BLACK, backRank[f])
            }
            return b
        }
    }
}
