package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.QuotaState

/**
 * Pure (state, event) -> state reducer. Mirrors `BuddyAICore.QuotaTracker`.
 */
object QuotaTracker {

    const val FREE_DAILY_LIMIT = 10
    const val CHATS_PER_AD = 5

    sealed interface Event {
        data object ChatStarted : Event
        data object AdWatched : Event
        data class Rollover(val toDay: String) : Event
    }

    data class Decision(
        val allowed: Boolean,
        val chatsRemaining: Int,
        val canWatchAd: Boolean,
    )

    fun reduce(state: QuotaState, event: Event, proUnlocked: Boolean): QuotaState =
        when (event) {
            is Event.ChatStarted ->
                if (proUnlocked) state else state.copy(chatsUsed = state.chatsUsed + 1)
            is Event.AdWatched ->
                if (proUnlocked) state else state.copy(adUnlocks = state.adUnlocks + 1)
            is Event.Rollover ->
                QuotaState(profileId = state.profileId, day = event.toDay)
        }

    fun decide(state: QuotaState, proUnlocked: Boolean): Decision {
        if (proUnlocked) return Decision(true, Int.MAX_VALUE, false)
        val allowance = FREE_DAILY_LIMIT + state.adUnlocks * CHATS_PER_AD
        val remaining = (allowance - state.chatsUsed).coerceAtLeast(0)
        return Decision(remaining > 0, remaining, true)
    }
}
