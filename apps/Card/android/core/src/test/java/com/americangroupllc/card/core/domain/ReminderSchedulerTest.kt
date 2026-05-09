package com.americangroupllc.card.core.domain

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ReminderSchedulerTest {
    private val now = 1_700_000_000_000L

    @Test fun `next fire time returns future unchanged`() {
        val future = now + 120_000L
        assertThat(ReminderScheduler.nextFireTime(future, now)).isEqualTo(future)
    }

    @Test fun `next fire time returns null for past`() {
        assertThat(ReminderScheduler.nextFireTime(now - 1, now)).isNull()
    }

    @Test fun `next fire time returns null for now`() {
        assertThat(ReminderScheduler.nextFireTime(now, now)).isNull()
    }

    @Test fun `group by minute collapses identical minutes`() {
        val tz = TimeZone.getTimeZone("UTC")
        val cal = Calendar.getInstance(tz).apply {
            set(2026, Calendar.MAY, 6, 9, 30, 0); set(Calendar.MILLISECOND, 0)
        }
        val minute = cal.timeInMillis
        val a = Card(text = "a", kind = CardKind.REMINDER, reminderAtEpochMs = minute + 5_000L,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val b = Card(text = "b", kind = CardKind.REMINDER, reminderAtEpochMs = minute + 40_000L,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val c = Card(text = "c", kind = CardKind.REMINDER, reminderAtEpochMs = minute + 60L * 60L * 1000L,
            createdAtEpochMs = now, updatedAtEpochMs = now)

        val buckets = ReminderScheduler.groupByMinute(listOf(a, b, c), tz, now)
        assertThat(buckets).hasSize(2)
        assertThat(buckets[minute]).isEqualTo(2)
    }

    @Test fun `group by minute ignores past reminders`() {
        val past = now - 3600_000L
        val card = Card(text = "x", kind = CardKind.REMINDER, reminderAtEpochMs = past,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        assertThat(ReminderScheduler.groupByMinute(listOf(card), TimeZone.getTimeZone("UTC"), now)).isEmpty()
    }

    @Test fun `group by minute ignores non-reminder kinds`() {
        val future = now + 60_000L
        val note = Card(text = "x", kind = CardKind.NOTE, reminderAtEpochMs = future,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        val task = Card(text = "y", kind = CardKind.TASK, reminderAtEpochMs = future,
            createdAtEpochMs = now, updatedAtEpochMs = now)
        assertThat(ReminderScheduler.groupByMinute(listOf(note, task), TimeZone.getTimeZone("UTC"), now)).isEmpty()
    }
}
