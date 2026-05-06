package com.americangroupllc.card.core.models

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
enum class CardKind { NOTE, TASK, REMINDER }

/**
 * Card — the single domain object. Mirrored case-for-case in
 * shared/CardCore/Sources/CardCore/Models/Card.swift
 *
 * Dates are stored as epoch milliseconds for serialization friendliness; the
 * UI/services layer converts to/from java.time.Instant as needed.
 */
@Serializable
data class Card(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val kind: CardKind = CardKind.NOTE,
    val reminderAtEpochMs: Long? = null,
    val completedAtEpochMs: Long? = null,
    val createdAtEpochMs: Long = System.currentTimeMillis(),
    val updatedAtEpochMs: Long = System.currentTimeMillis(),
) {
    val isCompleted: Boolean get() = completedAtEpochMs != null
}
