package com.americangroupllc.card.data

import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.storage.CardRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class CardRepositoryImpl @Inject constructor(
    private val dao: CardDao,
) : CardRepository {
    override fun observeAll(): Flow<List<Card>> =
        dao.observeAll().map { rows -> rows.map { it.toDomain() } }

    override suspend fun upsert(card: Card) =
        dao.upsert(CardEntity.fromDomain(card))

    override suspend fun delete(id: String) =
        dao.deleteById(id)

    override suspend fun getAll(): List<Card> =
        dao.getAll().map { it.toDomain() }
}
