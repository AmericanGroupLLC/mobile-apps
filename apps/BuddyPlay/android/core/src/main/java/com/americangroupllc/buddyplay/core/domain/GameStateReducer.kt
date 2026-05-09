package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer

/**
 * Pure `(state, input) -> state` reducer. Each game module conforms to this
 * with its own `State` and `Input` types. The connectivity layer just
 * routes inputs in and broadcasts the new state out.
 */
interface GameStateReducer<S, I> {

    fun initialState(host: Peer, guest: Peer): S

    /**
     * Apply a single input. Returns the new state and an optional
     * "outcome" (winner or draw) when the game just ended.
     * Throws [IllegalMoveException] if the input violates game rules.
     */
    fun reduce(state: S, input: I): Step<S>

    fun isFinal(state: S): Boolean

    /** The peer whose turn it currently is, or `null` for non-turn-based games. */
    fun currentTurn(state: S): String?

    data class Step<S>(val state: S, val outcome: Outcome? = null)

    sealed class Outcome {
        data class Winner(val peerId: String) : Outcome()
        object Draw : Outcome()
    }

    sealed class Error(message: String) : RuntimeException(message) {
        data class Illegal(val reason: String) : Error("illegal move: $reason")
        object WrongTurn : Error("not your turn")
        object GameOver  : Error("game is over")
    }
}
