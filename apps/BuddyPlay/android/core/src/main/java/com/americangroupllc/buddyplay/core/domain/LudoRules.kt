package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import kotlinx.serialization.Serializable

/**
 * Pure Ludo (Dice Kingdom) rules. 2-player, 4 tokens each, deterministic
 * dice rolls supplied via [LudoMove.diceRoll].
 *
 * See `shared/BuddyCore/Sources/BuddyCore/Domain/LudoRules.swift` for the
 * board model. This is a case-for-case mirror.
 */
object LudoRules : GameStateReducer<LudoState, LudoMove> {

    private val safeSquares = setOf(0, 8, 13, 21, 26, 34, 39, 47)

    override fun initialState(host: Peer, guest: Peer): LudoState =
        LudoState(
            red = host.id,
            blue = guest.id,
            tokens = mutableMapOf(
                host.id  to mutableListOf(-1, -1, -1, -1),
                guest.id to mutableListOf(-1, -1, -1, -1),
            ),
            sideToMove = host.id,
            consecutiveSixes = 0,
            lastDie = null,
            outcome = null,
        )

    override fun reduce(state: LudoState, input: LudoMove): GameStateReducer.Step<LudoState> {
        if (state.outcome != null) throw GameStateReducer.Error.GameOver
        if (input.player != state.sideToMove) throw GameStateReducer.Error.WrongTurn
        val die = input.diceRoll
        if (die !in 1..6) throw GameStateReducer.Error.Illegal("die $die not in 1..6")

        var s = state.copy(
            tokens = HashMap(state.tokens.mapValues { ArrayList(it.value) }),
        )
        s.lastDie = die

        if (die == 6) {
            s.consecutiveSixes += 1
            if (s.consecutiveSixes >= 3) {
                s.consecutiveSixes = 0
                s.sideToMove = opponent(input.player, s)
                return GameStateReducer.Step(s, null)
            }
        } else {
            s.consecutiveSixes = 0
        }

        if (input.tokenIndex != null) {
            advanceToken(s, input.player, input.tokenIndex, die)
        } else {
            if (hasAnyLegalMove(s, input.player, die)) {
                throw GameStateReducer.Error.Illegal("must move a token (a legal move exists)")
            }
        }

        if (s.tokens[input.player]!!.all { it == finalHome(input.player, s) }) {
            s.outcome = LudoOutcome.Winner(input.player)
            return GameStateReducer.Step(s, GameStateReducer.Outcome.Winner(input.player))
        }

        if (die != 6) s.sideToMove = opponent(input.player, s)
        return GameStateReducer.Step(s, null)
    }

    override fun isFinal(state: LudoState): Boolean = state.outcome != null

    override fun currentTurn(state: LudoState): String? =
        if (state.outcome != null) null else state.sideToMove

    fun legalTokenIndices(state: LudoState, player: String, die: Int): List<Int> {
        val out = mutableListOf<Int>()
        val tokens = state.tokens[player]!!
        for ((idx, pos) in tokens.withIndex()) {
            if (pos == -1) {
                if (die == 6) out += idx
                continue
            }
            if (pos == finalHome(player, state)) continue
            if (projectedPosition(player, state, pos, die) != null) out += idx
        }
        return out
    }

    private fun hasAnyLegalMove(s: LudoState, player: String, die: Int): Boolean =
        legalTokenIndices(s, player, die).isNotEmpty()

    private fun opponent(p: String, s: LudoState): String = if (p == s.red) s.blue else s.red

    private fun finalHome(player: String, s: LudoState): Int = if (player == s.red) 105 else 205

    private fun advanceToken(s: LudoState, player: String, tokenIndex: Int, die: Int) {
        val tokens = s.tokens[player]!! as MutableList<Int>
        val pos = tokens[tokenIndex]
        if (pos == -1) {
            if (die != 6) throw GameStateReducer.Error.Illegal("need a 6 to leave base")
            val entry = entrySquare(player, s)
            tokens[tokenIndex] = entry
            applyCapture(s, player, entry)
            return
        }
        val target = projectedPosition(player, s, pos, die)
            ?: throw GameStateReducer.Error.Illegal("would overshoot final home")
        tokens[tokenIndex] = target
        applyCapture(s, player, target)
    }

    private fun projectedPosition(player: String, s: LudoState, pos: Int, die: Int): Int? {
        val homeEntry = homeColumnEntrySquare(player, s)
        val homeBase = if (player == s.red) 100 else 200
        val homeFinal = finalHome(player, s)

        if (pos in homeBase..homeFinal) {
            val target = pos + die
            return if (target <= homeFinal) target else null
        }

        var stepsLeft = die
        var current = pos
        while (stepsLeft > 0) {
            if (current == homeEntry) {
                val target = homeBase + stepsLeft - 1
                return if (target <= homeFinal) target else null
            }
            current = (current + 1) % 52
            stepsLeft -= 1
        }
        return current
    }

    private fun entrySquare(player: String, s: LudoState): Int = if (player == s.red) 0 else 26
    private fun homeColumnEntrySquare(player: String, s: LudoState): Int = if (player == s.red) 50 else 24

    private fun applyCapture(s: LudoState, player: String, pos: Int) {
        if (pos >= 100) return
        if (pos in safeSquares) return
        val opp = opponent(player, s)
        val oppTokens = s.tokens[opp]!! as MutableList<Int>
        for (i in oppTokens.indices) {
            if (oppTokens[i] == pos) oppTokens[i] = -1
        }
    }
}

@Serializable
data class LudoMove(
    val player: String,
    val diceRoll: Int,
    val tokenIndex: Int?,
)

@Serializable
data class LudoState(
    val red: String,
    val blue: String,
    val tokens: MutableMap<String, MutableList<Int>>,
    var sideToMove: String,
    var consecutiveSixes: Int,
    var lastDie: Int?,
    var outcome: LudoOutcome?,
)

@Serializable
sealed class LudoOutcome {
    @Serializable data class Winner(val peerId: String) : LudoOutcome()
    @Serializable data class Resignation(val loser: String) : LudoOutcome()
}
