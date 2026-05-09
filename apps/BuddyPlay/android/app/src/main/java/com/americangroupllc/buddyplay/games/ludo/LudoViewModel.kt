package com.americangroupllc.buddyplay.games.ludo

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.americangroupllc.buddyplay.core.domain.GameStateReducer
import com.americangroupllc.buddyplay.core.domain.LudoMove
import com.americangroupllc.buddyplay.core.domain.LudoRules
import com.americangroupllc.buddyplay.core.domain.LudoState
import com.americangroupllc.buddyplay.core.models.Peer
import kotlin.random.Random

class LudoViewModel(host: Peer, guest: Peer) : ViewModel() {
    val host = host
    val guest = guest

    var state: LudoState by mutableStateOf(LudoRules.initialState(host, guest))
        private set
    var lastDieRoll: Int? by mutableStateOf(null)
        private set
    var lastError: String? by mutableStateOf(null)
        private set

    fun rollDie() {
        val die = Random.nextInt(1, 7)
        lastDieRoll = die
        val player = state.sideToMove
        val legal = LudoRules.legalTokenIndices(state, player, die)
        if (legal.isEmpty()) {
            commit(LudoMove(player, die, null))
        }
    }

    fun moveToken(tokenIndex: Int) {
        val die = lastDieRoll ?: return
        commit(LudoMove(state.sideToMove, die, tokenIndex))
    }

    val legalTokenIndices: List<Int>
        get() = lastDieRoll?.let { LudoRules.legalTokenIndices(state, state.sideToMove, it) } ?: emptyList()

    private fun commit(move: LudoMove) {
        try {
            val step = LudoRules.reduce(state, move)
            state = step.state
            lastDieRoll = null
        } catch (e: GameStateReducer.Error) {
            lastError = e.message
        }
    }
}
