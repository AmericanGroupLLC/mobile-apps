package com.americangroupllc.card.feed

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.card.core.domain.CardKindTransitions
import com.americangroupllc.card.core.domain.CardSorter
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind
import com.americangroupllc.card.core.obs.AnalyticsEvent
import com.americangroupllc.card.core.obs.AnalyticsService
import com.americangroupllc.card.core.obs.Surface
import com.americangroupllc.card.core.storage.CardRepository
import com.americangroupllc.card.reminder.ReminderService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FeedViewModel @Inject constructor(
    private val repo: CardRepository,
    private val reminderService: ReminderService,
) : ViewModel() {

    val cards: StateFlow<List<Card>> =
        repo.observeAll()
            .map { CardSorter.sort(it) }
            .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    fun capture(text: String) = viewModelScope.launch {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return@launch
        val card = Card(text = trimmed)
        repo.upsert(card)
        AnalyticsService.shared.track(AnalyticsEvent.CardCaptured(Surface.APP, CardKind.NOTE))
    }

    fun convert(card: Card, target: CardKind, reminderAtEpochMs: Long? = null) = viewModelScope.launch {
        val next = CardKindTransitions.convert(card, target, reminderAtEpochMs) ?: return@launch
        repo.upsert(next)
        AnalyticsService.shared.track(AnalyticsEvent.CardConverted(card.kind, target))
        if (next.kind == CardKind.REMINDER) reminderService.schedule(next)
        else reminderService.cancel(next.id)
    }

    fun toggleCompleted(card: Card) = viewModelScope.launch {
        repo.upsert(CardKindTransitions.toggleCompleted(card))
    }

    fun update(card: Card, text: String) = viewModelScope.launch {
        repo.upsert(card.copy(text = text.trim(), updatedAtEpochMs = System.currentTimeMillis()))
    }

    fun delete(card: Card) = viewModelScope.launch {
        repo.delete(card.id)
        reminderService.cancel(card.id)
        AnalyticsService.shared.track(AnalyticsEvent.CardDeleted(card.kind))
    }

    fun eraseAll() = viewModelScope.launch {
        repo.getAll().forEach { reminderService.cancel(it.id) }
        repo.getAll().forEach { repo.delete(it.id) }
    }
}
