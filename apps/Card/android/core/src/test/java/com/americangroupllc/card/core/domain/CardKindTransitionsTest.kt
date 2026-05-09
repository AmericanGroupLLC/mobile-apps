package com.americangroupllc.card.core.domain

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class CardKindTransitionsTest {
    private val now = 1_700_000_000_000L
    private val futureMs = now + 60L * 60L * 1000L
    private val pastMs   = now - 60L * 60L * 1000L

    @Test fun `identity transition for note is no-op`() {
        val card = Card(text = "hi", kind = CardKind.NOTE, createdAtEpochMs = now, updatedAtEpochMs = now)
        assertThat(CardKindTransitions.convert(card, CardKind.NOTE, nowEpochMs = now)).isEqualTo(card)
    }

    @Test fun `note to task clears reminderAt`() {
        val card = Card(text = "x", kind = CardKind.NOTE, reminderAtEpochMs = futureMs,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardKindTransitions.convert(card, CardKind.TASK, nowEpochMs = now)
        assertThat(r?.kind).isEqualTo(CardKind.TASK)
        assertThat(r?.reminderAtEpochMs).isNull()
    }

    @Test fun `note to reminder requires future date`() {
        val card = Card(text = "x", kind = CardKind.NOTE, createdAtEpochMs = now, updatedAtEpochMs = now)
        assertThat(CardKindTransitions.convert(card, CardKind.REMINDER, null,        now)).isNull()
        assertThat(CardKindTransitions.convert(card, CardKind.REMINDER, pastMs,      now)).isNull()
        assertThat(CardKindTransitions.convert(card, CardKind.REMINDER, now,         now)).isNull()
        val r = CardKindTransitions.convert(card, CardKind.REMINDER, futureMs, now)
        assertThat(r?.kind).isEqualTo(CardKind.REMINDER)
        assertThat(r?.reminderAtEpochMs).isEqualTo(futureMs)
    }

    @Test fun `task to note clears completedAt`() {
        val card = Card(text = "x", kind = CardKind.TASK, completedAtEpochMs = now,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardKindTransitions.convert(card, CardKind.NOTE, nowEpochMs = now)
        assertThat(r?.kind).isEqualTo(CardKind.NOTE)
        assertThat(r?.completedAtEpochMs).isNull()
    }

    @Test fun `reminder to task clears reminderAt`() {
        val card = Card(text = "x", kind = CardKind.REMINDER, reminderAtEpochMs = futureMs,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardKindTransitions.convert(card, CardKind.TASK, nowEpochMs = now)
        assertThat(r?.kind).isEqualTo(CardKind.TASK)
        assertThat(r?.reminderAtEpochMs).isNull()
    }

    @Test fun `toggle completed only affects tasks`() {
        val note = Card(text = "x", kind = CardKind.NOTE, createdAtEpochMs = now, updatedAtEpochMs = now)
        assertThat(CardKindTransitions.toggleCompleted(note, now).isCompleted).isFalse()

        val task = Card(text = "x", kind = CardKind.TASK, createdAtEpochMs = now, updatedAtEpochMs = now)
        val toggled = CardKindTransitions.toggleCompleted(task, now)
        assertThat(toggled.isCompleted).isTrue()
        assertThat(CardKindTransitions.toggleCompleted(toggled, now).isCompleted).isFalse()
    }

    @Test fun `convert updates updatedAt`() {
        val card = Card(text = "x", kind = CardKind.NOTE, createdAtEpochMs = now, updatedAtEpochMs = now)
        val later = now + 60_000L
        val r = CardKindTransitions.convert(card, CardKind.TASK, nowEpochMs = later)
        assertThat(r?.updatedAtEpochMs).isEqualTo(later)
    }
}
