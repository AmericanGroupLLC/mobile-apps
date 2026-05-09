package com.americangroupllc.card.core.domain

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind

/**
 * Pure logic for note ↔ task ↔ reminder transitions. Mirrors
 * shared/CardCore/Sources/CardCore/Domain/CardKindTransitions.swift
 */
object CardKindTransitions {

    /**
     * Convert [card] to [target]. Clears the irrelevant fields per kind.
     * For [CardKind.REMINDER], [reminderAtEpochMs] MUST be in the future or
     * this returns null.
     */
    fun convert(
        card: Card,
        target: CardKind,
        reminderAtEpochMs: Long? = null,
        nowEpochMs: Long = System.currentTimeMillis(),
    ): Card? {
        if (card.kind == target && target != CardKind.REMINDER) {
            return card
        }
        return when (target) {
            CardKind.NOTE -> card.copy(
                kind = CardKind.NOTE,
                reminderAtEpochMs = null,
                completedAtEpochMs = null,
                updatedAtEpochMs = nowEpochMs,
            )
            CardKind.TASK -> card.copy(
                kind = CardKind.TASK,
                reminderAtEpochMs = null,
                updatedAtEpochMs = nowEpochMs,
            )
            CardKind.REMINDER -> {
                if (reminderAtEpochMs == null || reminderAtEpochMs <= nowEpochMs) return null
                card.copy(
                    kind = CardKind.REMINDER,
                    reminderAtEpochMs = reminderAtEpochMs,
                    completedAtEpochMs = null,
                    updatedAtEpochMs = nowEpochMs,
                )
            }
        }
    }

    /** Toggle a task's completion state. No-op for non-tasks. */
    fun toggleCompleted(
        card: Card,
        nowEpochMs: Long = System.currentTimeMillis(),
    ): Card {
        if (card.kind != CardKind.TASK) return card
        return card.copy(
            completedAtEpochMs = if (card.isCompleted) null else nowEpochMs,
            updatedAtEpochMs = nowEpochMs,
        )
    }
}
