package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class LudoRulesKtTest {

    private fun newGame(): Triple<LudoState, String, String> {
        val h = Peer("00000000-0000-0000-0000-000000000001", "H", Peer.Platform.IOS, 0L)
        val g = Peer("00000000-0000-0000-0000-000000000002", "G", Peer.Platform.ANDROID, 0L)
        return Triple(LudoRules.initialState(h, g), h.id, g.id)
    }

    @Test(expected = GameStateReducer.Error.Illegal::class)
    fun cannotLeaveBaseWithoutSix() {
        val (s0, h, _) = newGame()
        LudoRules.reduce(s0, LudoMove(h, 3, 0))
    }

    @Test
    fun rollingSixGrantsExtraTurn() {
        val (s0, h, _) = newGame()
        val s1 = LudoRules.reduce(s0, LudoMove(h, 6, 0)).state
        assertThat(s1.sideToMove).isEqualTo(h)
        assertThat(s1.tokens[h]!![0]).isEqualTo(0)
    }

    @Test
    fun nonSixRotatesTurn() {
        val (s0, h, g) = newGame()
        val s1 = LudoRules.reduce(s0, LudoMove(h, 4, null)).state
        assertThat(s1.sideToMove).isEqualTo(g)
    }

    @Test
    fun threeConsecutiveSixesForfeitsTurn() {
        val (s0, h, g) = newGame()
        var s = s0
        s = LudoRules.reduce(s, LudoMove(h, 6, 0)).state
        s = LudoRules.reduce(s, LudoMove(h, 6, 1)).state
        s = LudoRules.reduce(s, LudoMove(h, 6, null)).state
        assertThat(s.sideToMove).isEqualTo(g)
    }

    @Test
    fun captureSendsOpponentHome() {
        val (s0, h, g) = newGame()
        val tokens = HashMap<String, MutableList<Int>>(s0.tokens)
        tokens[g] = mutableListOf(4, -1, -1, -1)
        val s = s0.copy(tokens = tokens)

        val s1 = LudoRules.reduce(s, LudoMove(h, 6, 0)).state          // host out at 0
        val s2 = LudoRules.reduce(s1, LudoMove(h, 4, 0)).state         // host advances 0→4, captures
        assertThat(s2.tokens[h]!![0]).isEqualTo(4)
        assertThat(s2.tokens[g]!![0]).isEqualTo(-1)
    }
}
