package com.americangroupllc.drift.core.domain

import com.americangroupllc.drift.core.models.Intent
import com.americangroupllc.drift.core.models.Layer
import com.americangroupllc.drift.core.models.Message
import com.americangroupllc.drift.core.models.Profile
import com.americangroupllc.drift.core.models.Tone
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ReplyPromptBuilderTest {

    private val viewer = Profile(
        id = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
        displayName = "Sara",
        intent = Intent.DATING,
        vibeTags = listOf("coffee", "books"),
        zipPrefix3 = "940",
        countyFips = "06085",
        stateCode = "CA",
        lastActiveAt = 0,
        createdAt = 0,
    )
    private val target = Profile(
        id = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
        displayName = "Maya",
        intent = Intent.SERIOUS,
        vibeTags = listOf("hiking", "music"),
        zipPrefix3 = "940",
        countyFips = "06085",
        stateCode = "CA",
        lastActiveAt = 0,
        createdAt = 0,
    )

    @Test fun `system contains strict json contract`() {
        val out = ReplyPromptBuilder.build(
            ReplyPromptBuilder.Inputs(viewer, target, emptyList(), Tone.SLOW))
        assertThat(out.system).contains("strict JSON")
        assertThat(out.system).contains("\"casual\"")
        assertThat(out.system).contains("private location")
    }

    @Test fun `user section includes both profiles and vibes`() {
        val out = ReplyPromptBuilder.build(
            ReplyPromptBuilder.Inputs(viewer, target, emptyList(), Tone.SLOW))
        assertThat(out.user).contains("Sara")
        assertThat(out.user).contains("Maya")
        assertThat(out.user).contains("dating")
        assertThat(out.user).contains("serious")
        assertThat(out.user).contains("coffee")
        assertThat(out.user).contains("hiking")
    }

    @Test fun `messages appear in chronological order`() {
        val now = 1_700_000_000_000L
        val msgs = listOf(
            Message("m1", "c", viewer.id, "first",  now - 120_000L),
            Message("m2", "c", target.id, "second", now -  60_000L),
            Message("m3", "c", viewer.id, "third",  now),
        )
        val out = ReplyPromptBuilder.build(
            ReplyPromptBuilder.Inputs(viewer, target, msgs, Tone.ENERGETIC))
        assertThat(out.user.indexOf("first")).isLessThan(out.user.indexOf("second"))
        assertThat(out.user.indexOf("second")).isLessThan(out.user.indexOf("third"))
    }

    @Test fun `meetup_ready tone clause appears`() {
        val out = ReplyPromptBuilder.build(
            ReplyPromptBuilder.Inputs(viewer, target, emptyList(), Tone.MEETUP_READY))
        assertThat(out.system).contains("public-place")
    }

    @Test fun `golden snapshot for fixed inputs`() {
        val out = ReplyPromptBuilder.build(
            ReplyPromptBuilder.Inputs(viewer, target, emptyList(), Tone.SLOW))
        val expected = """
            Person A: Sara (intent: dating, vibes: coffee, books)
            Person B: Maya (intent: serious, vibes: hiking, music)

            Last messages (oldest → newest):
            (no messages yet — these are opener suggestions)
        """.trimIndent()
        assertThat(out.user).isEqualTo(expected)
    }
}
