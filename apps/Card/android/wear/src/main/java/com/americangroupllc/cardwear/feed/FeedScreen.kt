package com.americangroupllc.cardwear.feed

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Text
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.storage.InMemoryCardRepository
import androidx.compose.runtime.collectAsState

private val watchRepo = InMemoryCardRepository()

@Composable
fun FeedScreen(onCapture: () -> Unit) {
    val cards: List<Card> = watchRepo.observeAll().collectAsState(initial = emptyList()).value
    val state = rememberScalingLazyListState()
    ScalingLazyColumn(state = state, modifier = Modifier.fillMaxWidth()) {
        item {
            Chip(
                label = { Text("+ Capture") },
                onClick = onCapture,
                colors = ChipDefaults.primaryChipColors(),
                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
            )
        }
        items(cards, key = { it.id }) { card ->
            Chip(
                label = { Text(card.text, maxLines = 2) },
                onClick = { /* tap to expand — out of v1 */ },
                modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
            )
        }
    }
}

internal val sharedRepo: InMemoryCardRepository get() = watchRepo
