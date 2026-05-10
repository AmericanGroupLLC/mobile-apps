package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.QuotaState
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.util.UUID

class QuotaTrackerKtTest {

    private val pid = UUID.randomUUID().toString()

    @Test
    fun free_tier_allows_10_chats_then_blocks() {
        var s = QuotaState(profileId = pid, day = "2026-05-06")
        repeat(10) {
            assertThat(QuotaTracker.decide(s, proUnlocked = false).allowed).isTrue()
            s = QuotaTracker.reduce(s, QuotaTracker.Event.ChatStarted, proUnlocked = false)
        }
        assertThat(QuotaTracker.decide(s, proUnlocked = false).allowed).isFalse()
    }

    @Test
    fun ad_watch_grants_5_more_chats() {
        var s = QuotaState(profileId = pid, day = "2026-05-06", chatsUsed = 10)
        assertThat(QuotaTracker.decide(s, proUnlocked = false).allowed).isFalse()
        s = QuotaTracker.reduce(s, QuotaTracker.Event.AdWatched, proUnlocked = false)
        assertThat(QuotaTracker.decide(s, proUnlocked = false).chatsRemaining).isEqualTo(5)
    }

    @Test
    fun midnight_rollover_resets() {
        var s = QuotaState(profileId = pid, day = "2026-05-06", chatsUsed = 10, adUnlocks = 1)
        s = QuotaTracker.reduce(s, QuotaTracker.Event.Rollover("2026-05-07"), proUnlocked = false)
        assertThat(s.chatsUsed).isEqualTo(0)
        assertThat(s.adUnlocks).isEqualTo(0)
        assertThat(s.day).isEqualTo("2026-05-07")
    }

    @Test
    fun pro_entitlement_bypasses_quota() {
        var s = QuotaState(profileId = pid, day = "2026-05-06", chatsUsed = 1_000_000)
        assertThat(QuotaTracker.decide(s, proUnlocked = true).allowed).isTrue()
        s = QuotaTracker.reduce(s, QuotaTracker.Event.ChatStarted, proUnlocked = true)
        assertThat(s.chatsUsed).isEqualTo(1_000_000)
    }
}
