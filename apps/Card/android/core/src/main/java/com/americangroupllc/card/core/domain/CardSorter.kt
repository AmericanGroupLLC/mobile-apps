package com.americangroupllc.card.core.domain

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind

/**
 * Pure feed-sort logic. Mirrors
 * shared/CardCore/Sources/CardCore/Domain/CardSorter.swift
 *
 * Sort order (top → bottom):
 *   1. Reminders due in the next 24h (closest fire-time first)
 *   2. All other reminders / notes / tasks (newest updatedAt first)
 *   3. Completed tasks (most recently completed first)
 */
object CardSorter {
    private const val DAY_MS = 24L * 60L * 60L * 1000L

    fun sort(
        cards: List<Card>,
        nowEpochMs: Long = System.currentTimeMillis(),
    ): List<Card> {
        val dueSoonCutoff = nowEpochMs + DAY_MS

        val dueSoon = cards
            .filter { card ->
                card.kind == CardKind.REMINDER &&
                    !card.isCompleted &&
                    (card.reminderAtEpochMs?.let { it in (nowEpochMs + 1)..dueSoonCutoff } == true)
            }
            .sortedBy { it.reminderAtEpochMs ?: Long.MAX_VALUE }

        val dueSoonIds = dueSoon.map { it.id }.toSet()

        val middle = cards
            .filter { it.id !in dueSoonIds && !it.isCompleted }
            .sortedByDescending { it.updatedAtEpochMs }

        val bottom = cards
            .filter { it.isCompleted }
            .sortedByDescending { it.completedAtEpochMs ?: Long.MIN_VALUE }

        return dueSoon + middle + bottom
    }
}
