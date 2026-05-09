package com.americangroupllc.card.core.storage

import com.americangroupllc.card.core.models.Card
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Test-only in-memory implementation of [CardRepository]. */
class InMemoryCardRepository(initial: List<Card> = emptyList()) : CardRepository {
    private val _cards = MutableStateFlow(initial)

    override fun observeAll(): StateFlow<List<Card>> = _cards.asStateFlow()

    override suspend fun upsert(card: Card) {
        _cards.value = _cards.value.filterNot { it.id == card.id } + card
    }

    override suspend fun delete(id: String) {
        _cards.value = _cards.value.filterNot { it.id == id }
    }

    override suspend fun getAll(): List<Card> = _cards.value
}
