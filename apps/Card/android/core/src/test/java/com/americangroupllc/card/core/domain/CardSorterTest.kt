package com.americangroupllc.card.core.domain

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class CardSorterTest {
    private val now = 1_700_000_000_000L

    @Test fun `empty input returns empty`() {
        assertThat(CardSorter.sort(emptyList(), now)).isEmpty()
    }

    @Test fun `completed tasks go to bottom`() {
        val openNote = Card(text = "open", kind = CardKind.NOTE,
            createdAtEpochMs = now, updatedAtEpochMs = now - 60_000L)
        val doneTask = Card(text = "done", kind = CardKind.TASK,
            completedAtEpochMs = now - 30_000L,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardSorter.sort(listOf(doneTask, openNote), now)
        assertThat(r.first().id).isEqualTo(openNote.id)
        assertThat(r.last().id).isEqualTo(doneTask.id)
    }

    @Test fun `due-soon reminders pinned to top`() {
        val dueIn1h = Card(text = "soon", kind = CardKind.REMINDER,
            reminderAtEpochMs = now + 3_600_000L,
            createdAtEpochMs = now, updatedAtEpochMs = now - 1_000_000L)
        val recentNote = Card(text = "recent", kind = CardKind.NOTE,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardSorter.sort(listOf(recentNote, dueIn1h), now)
        assertThat(r.first().id).isEqualTo(dueIn1h.id)
    }

    @Test fun `reminders beyond 24h are not pinned`() {
        val far = Card(text = "later", kind = CardKind.REMINDER,
            reminderAtEpochMs = now + 48L * 3_600_000L,
            createdAtEpochMs = now, updatedAtEpochMs = now - 1_000_000L)
        val recentNote = Card(text = "recent", kind = CardKind.NOTE,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardSorter.sort(listOf(far, recentNote), now)
        assertThat(r.first().id).isEqualTo(recentNote.id)
    }

    @Test fun `middle sorted by updatedAt descending`() {
        val older = Card(text = "older", kind = CardKind.NOTE,
            createdAtEpochMs = now, updatedAtEpochMs = now - 200_000L)
        val newer = Card(text = "newer", kind = CardKind.NOTE,
            createdAtEpochMs = now, updatedAtEpochMs = now - 50_000L)
        val r = CardSorter.sort(listOf(older, newer), now)
        assertThat(r.map { it.text }).containsExactly("newer", "older").inOrder()
    }

    @Test fun `composite ordering`() {
        val dueSoon = Card(text = "due-soon", kind = CardKind.REMINDER,
            reminderAtEpochMs = now + 30L * 60L * 1000L,
            createdAtEpochMs = now, updatedAtEpochMs = now - 5_000_000L)
        val recent  = Card(text = "recent", kind = CardKind.NOTE,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val done    = Card(text = "done", kind = CardKind.TASK,
            completedAtEpochMs = now,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val r = CardSorter.sort(listOf(done, recent, dueSoon), now)
        assertThat(r.map { it.text }).containsExactly("due-soon", "recent", "done").inOrder()
    }
}
