package com.americangroupllc.buddyplay.games.chess

import androidx.lifecycle.ViewModel
import com.americangroupllc.buddyplay.core.domain.ChessMove
import com.americangroupllc.buddyplay.core.domain.ChessPieceKind
import com.americangroupllc.buddyplay.core.domain.ChessRules
import com.americangroupllc.buddyplay.core.domain.ChessSquare
import com.americangroupllc.buddyplay.core.domain.ChessState
import com.americangroupllc.buddyplay.core.domain.GameStateReducer
import com.americangroupllc.buddyplay.core.models.Peer
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

class ChessViewModel(host: Peer, guest: Peer) : ViewModel() {

    val host: Peer = host
    val guest: Peer = guest

    var state: ChessState by mutableStateOf(ChessRules.initialState(host, guest))
        private set

    var selected: ChessSquare? by mutableStateOf(null)
        private set
    var legalDestinations: Set<ChessSquare> by mutableStateOf(emptySet())
        private set
    var lastError: String? by mutableStateOf(null)
        private set

    val isInCheck: Boolean get() = ChessRules.isInCheck(state, state.sideToMove)

    fun tap(square: ChessSquare) {
        val from = selected
        if (from != null) {
            if (square in legalDestinations) {
                commit(ChessMove(from, square, promotion = defaultPromotion(from, square)))
            } else {
                val piece = state.board[square]
                if (piece != null && piece.color == state.sideToMove) select(square)
                else clearSelection()
            }
        } else {
            select(square)
        }
    }

    private fun select(square: ChessSquare) {
        val piece = state.board[square]
        if (piece == null || piece.color != state.sideToMove) {
            clearSelection()
            return
        }
        selected = square
        legalDestinations = ChessRules.legalMoves(state, piece.color)
            .filter { it.from == square }
            .map { it.to }
            .toSet()
    }

    private fun clearSelection() {
        selected = null
        legalDestinations = emptySet()
    }

    private fun commit(move: ChessMove) {
        try {
            val step = ChessRules.reduce(state, move)
            state = step.state
            clearSelection()
        } catch (e: GameStateReducer.Error) {
            lastError = e.message
            clearSelection()
        }
    }

    private fun defaultPromotion(from: ChessSquare, to: ChessSquare): ChessPieceKind? {
        val p = state.board[from] ?: return null
        if (p.kind != ChessPieceKind.PAWN) return null
        val promoRank = if (p.color == com.americangroupllc.buddyplay.core.domain.ChessColor.WHITE) 7 else 0
        return if (to.rank == promoRank) ChessPieceKind.QUEEN else null
    }
}
