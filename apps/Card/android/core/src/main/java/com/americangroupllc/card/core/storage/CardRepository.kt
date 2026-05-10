package com.americangroupllc.card.core.storage

import com.americangroupllc.card.core.models.Card
import kotlinx.coroutines.flow.Flow

/**
 * The repository contract. :app provides a Room-backed implementation;
 * :core provides [InMemoryCardRepository] for unit tests.
 */
interface CardRepository {
    fun observeAll(): Flow<List<Card>>
    suspend fun upsert(card: Card)
    suspend fun delete(id: String)
    suspend fun getAll(): List<Card>
}
