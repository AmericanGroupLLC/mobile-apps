package com.americangroupllc.buddyplay.core.models

import kotlinx.serialization.Serializable

/**
 * One cumulative head-to-head record against another peer, keyed by their
 * stable UUID. Persisted in [com.americangroupllc.buddyplay.core.storage.LocalRivalryStore].
 */
@Serializable
data class Rivalry(
    val opponentId: String,
    var opponentName: String,
    val perGame: MutableMap<GameKind, Record> = mutableMapOf(),
    var lastPlayedAt: Long,
) {
    @Serializable
    data class Record(
        var wins: Int = 0,
        var losses: Int = 0,
        var draws: Int = 0,
    ) {
        val totalPlayed: Int get() = wins + losses + draws
    }

    fun record(outcome: Outcome, kind: GameKind, atMillis: Long) {
        val rec = perGame.getOrPut(kind) { Record() }
        when (outcome) {
            Outcome.WIN  -> rec.wins   += 1
            Outcome.LOSS -> rec.losses += 1
            Outcome.DRAW -> rec.draws  += 1
        }
        lastPlayedAt = atMillis
    }

    @Serializable
    enum class Outcome { WIN, LOSS, DRAW }
}
