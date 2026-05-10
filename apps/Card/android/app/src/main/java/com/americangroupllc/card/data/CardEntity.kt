package com.americangroupllc.card.data

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind

@Entity(tableName = "cards")
data class CardEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "text") val text: String,
    @ColumnInfo(name = "kind") val kind: String,
    @ColumnInfo(name = "reminder_at_ms") val reminderAtEpochMs: Long?,
    @ColumnInfo(name = "completed_at_ms") val completedAtEpochMs: Long?,
    @ColumnInfo(name = "created_at_ms") val createdAtEpochMs: Long,
    @ColumnInfo(name = "updated_at_ms") val updatedAtEpochMs: Long,
) {
    fun toDomain(): Card = Card(
        id = id,
        text = text,
        kind = CardKind.valueOf(kind),
        reminderAtEpochMs = reminderAtEpochMs,
        completedAtEpochMs = completedAtEpochMs,
        createdAtEpochMs = createdAtEpochMs,
        updatedAtEpochMs = updatedAtEpochMs,
    )

    companion object {
        fun fromDomain(c: Card) = CardEntity(
            id = c.id,
            text = c.text,
            kind = c.kind.name,
            reminderAtEpochMs = c.reminderAtEpochMs,
            completedAtEpochMs = c.completedAtEpochMs,
            createdAtEpochMs = c.createdAtEpochMs,
            updatedAtEpochMs = c.updatedAtEpochMs,
        )
    }
}
