package com.americangroupllc.drift.core.domain

import com.americangroupllc.drift.core.models.Intent
import com.americangroupllc.drift.core.models.Layer
import com.americangroupllc.drift.core.models.Profile
import com.americangroupllc.drift.core.models.Prompt
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class LayerScorerTest {

    private fun profile(
        intent: Intent = Intent.DATING,
        verified: Boolean = true,
        zip: String? = "940",
        county: String? = "06085",
        state: String? = "CA",
        vibes: List<String> = listOf("coffee", "books"),
        prompts: Int = 3,
        voice: Boolean = true,
        lastActive: Long = System.currentTimeMillis(),
    ) = Profile(
        id = "p-${intent.name}-$lastActive-${vibes.hashCode()}",
        displayName = "X",
        photos = emptyList(),
        voicePromptUrl = if (voice) "https://example.com/v.m4a" else null,
        intent = intent,
        vibeTags = vibes,
        prompts = (1..prompts).map { Prompt(slot = it, key = "k$it", response = "r") },
        verifiedAt = if (verified) "2026-05-01T00:00:00Z" else null,
        zipPrefix3 = zip,
        countyFips = county,
        stateCode = state,
        lastActiveAt = lastActive,
        createdAt = lastActive - 86_400_000L,
    )

    @Test fun `high score on same zip both verified same intent`() {
        val s = LayerScorer.score(profile(), profile(), Layer.ZIP)
        assertThat(s).isAtLeast(0.85)
    }

    @Test fun `low score on different state and no shared interests`() {
        val viewer = profile(state = "CA", vibes = listOf("coffee"))
        val target = profile(intent = Intent.FRIENDSHIP, zip = "100", county = "36061",
                             state = "NY", vibes = listOf("chess"))
        val s = LayerScorer.score(viewer, target, Layer.STATE)
        assertThat(s).isLessThan(0.50)
    }

    @Test fun `weights sum to 1`() {
        val s = LayerScorer.score(profile(), profile(), Layer.ZIP)
        assertThat(s).isAtMost(1.0001)
        assertThat(s).isAtLeast(0.0)
    }

    @Test fun `ties break by recency`() {
        val now = 1_700_000_000_000L
        val older = profile(lastActive = now - 3_600_000)
        val newer = profile(lastActive = now)
        val sorted = LayerScorer.sorted(listOf(older, newer), profile(lastActive = now), Layer.ZIP, now)
        assertThat(sorted.first()).isEqualTo(newer)
    }

    @Test fun `intent score with OPEN is reasonable`() {
        assertThat(LayerScorer.intentScore(Intent.OPEN, Intent.FRIENDSHIP)).isGreaterThan(0.5)
        assertThat(LayerScorer.intentScore(Intent.DATING, Intent.OPEN)).isGreaterThan(0.5)
        assertThat(LayerScorer.intentScore(Intent.DATING, Intent.DATING)).isEqualTo(1.0)
    }

    @Test fun `recency score degrades`() {
        val now = 1_700_000_000_000L
        assertThat(LayerScorer.recentActivityScore(now, now)).isEqualTo(1.0)
        assertThat(LayerScorer.recentActivityScore(now - 2 * 24 * 3_600_000L, now)).isEqualTo(0.75)
        assertThat(LayerScorer.recentActivityScore(now - 365L * 24 * 3_600_000L, now)).isLessThan(0.1)
    }

    @Test fun `shared interests is jaccard`() {
        assertThat(LayerScorer.sharedInterests(listOf("a","b"), listOf("b","c"))).isWithin(0.001).of(1.0/3.0)
        assertThat(LayerScorer.sharedInterests(emptyList(), listOf("b"))).isEqualTo(0.0)
    }
}
