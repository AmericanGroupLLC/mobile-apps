package com.americangroupllc.drift.core.domain

import com.americangroupllc.drift.core.models.Message
import com.americangroupllc.drift.core.models.Tone
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ToneClassifierTest {

    private fun msg(text: String, atMillis: Long, by: String = "a") =
        Message(id = "m-$atMillis", conversationId = "c", authorId = by, text = text, createdAt = atMillis)

    @Test fun `empty messages return slow`() {
        assertThat(ToneClassifier.classify(emptyList())).isEqualTo(Tone.SLOW)
    }

    @Test fun `long gap keeps slow`() {
        val now = 1_700_000_000_000L
        val msgs = listOf(msg("hi", now - 5L * 3_600_000), msg("hey", now))
        assertThat(ToneClassifier.classify(msgs, now)).isEqualTo(Tone.SLOW)
    }

    @Test fun `ten messages in five minutes is energetic`() {
        val now = 1_700_000_000_000L
        val msgs = (0 until 10).map { msg("ping $it", now + it * 30_000L) }
        assertThat(ToneClassifier.classify(msgs, now + 5 * 60_000L)).isEqualTo(Tone.ENERGETIC)
    }

    @Test fun `long average length is deep`() {
        val now = 1_700_000_000_000L
        val long = "x".repeat(250)
        val msgs = listOf(msg(long, now - 60_000), msg(long, now))
        assertThat(ToneClassifier.classify(msgs, now)).isEqualTo(Tone.DEEP)
    }

    @Test fun `meetup keyword triggers meetup_ready`() {
        val now = 1_700_000_000_000L
        val msgs = listOf(msg("yeah want to grab coffee Sat?", now))
        assertThat(ToneClassifier.classify(msgs, now)).isEqualTo(Tone.MEETUP_READY)
    }
}
