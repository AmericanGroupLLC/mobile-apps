package com.americangroupllc.card.core.domain

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind
import java.util.Calendar
import java.util.TimeZone

/**
 * Pure-Kotlin "next fire time" math. Platform layers wrap AlarmManager around
 * the output. Mirrors shared/CardCore/Sources/CardCore/Domain/ReminderScheduler.swift
 */
object ReminderScheduler {

    /**
     * Returns [target] if it is strictly in the future relative to [nowEpochMs],
     * otherwise null. Card v1 has no recurring reminders.
     */
    fun nextFireTime(
        target: Long,
        nowEpochMs: Long = System.currentTimeMillis(),
    ): Long? = if (target > nowEpochMs) target else null

    /**
     * Group reminders that share the same calendar minute under a single
     * fire-time. Returns a map keyed by the floored-to-minute epoch ms with the
     * count of cards in that minute. Used to collapse spammy notifications into
     * a single grouped notification with a count badge.
     */
    fun groupByMinute(
        cards: List<Card>,
        timeZone: TimeZone = TimeZone.getDefault(),
        nowEpochMs: Long = System.currentTimeMillis(),
    ): Map<Long, Int> {
        val out = mutableMapOf<Long, Int>()
        val cal = Calendar.getInstance(timeZone)
        for (card in cards) {
            if (card.kind != CardKind.REMINDER) continue
            val at = card.reminderAtEpochMs ?: continue
            if (at <= nowEpochMs) continue
            cal.timeInMillis = at
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val floored = cal.timeInMillis
            out[floored] = (out[floored] ?: 0) + 1
        }
        return out
    }
}
