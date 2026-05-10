package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class GameStateReducerKtTest {

    private fun mkPeers(): Pair<Peer, Peer> {
        val h = Peer("00000000-0000-0000-0000-000000000001", "Host", Peer.Platform.IOS, 0L)
        val g = Peer("00000000-0000-0000-0000-000000000002", "Guest", Peer.Platform.ANDROID, 0L)
        return h to g
    }

    @Test
    fun chessReducerRotatesTurn() {
        val (h, g) = mkPeers()
        val s0 = ChessRules.initialState(h, g)
        assertThat(ChessRules.currentTurn(s0)).isEqualTo(h.id)
        val move = ChessMove(ChessSquare(4, 1), ChessSquare(4, 3))
        val step = ChessRules.reduce(s0, move)
        assertThat(ChessRules.currentTurn(step.state)).isEqualTo(g.id)
        assertThat(step.outcome).isNull()
    }

    @Test
    fun ludoReducerRotatesTurnUnlessSix() {
        val (h, g) = mkPeers()
        val s0 = LudoRules.initialState(h, g)
        // Roll a 1 — must pass.
        val s1 = LudoRules.reduce(s0, LudoMove(h.id, 1, null)).state
        assertThat(LudoRules.currentTurn(s1)).isEqualTo(g.id)
        // Now guest rolls a 6 — moves out, gets another turn.
        val s2 = LudoRules.reduce(s1, LudoMove(g.id, 6, 0)).state
        assertThat(LudoRules.currentTurn(s2)).isEqualTo(g.id)
    }

    @Test
    fun racerReducerAdvancesTickCount() {
        val (h, g) = mkPeers()
        val s0 = RacerPhysics.initialState(h, g)
        assertThat(s0.tickCount).isEqualTo(0)
        val input = RacerInput(h.id, throttle = 1.0, brake = 0.0, steering = 0.0)
        val s1 = RacerPhysics.reduce(s0, input).state
        assertThat(s1.tickCount).isEqualTo(1)
        assertThat(RacerPhysics.currentTurn(s1)).isNull()
    }
}
