package com.americangroupllc.cardwear.composer

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Text
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.obs.AnalyticsEvent
import com.americangroupllc.card.core.obs.AnalyticsService
import com.americangroupllc.card.core.obs.Surface
import com.americangroupllc.card.core.models.CardKind
import com.americangroupllc.cardwear.feed.sharedRepo
import kotlinx.coroutines.launch

/**
 * Voice-first composer. v1 ships with the watchOS-equivalent flow: tap the
 * field → system dictation/scribble UI takes over. Wear OS Compose's TextField
 * surfaces dictation by default on real devices.
 */
@Composable
fun ComposerScreen(onDone: () -> Unit) {
    var text by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 16.dp)
    ) {
        Text(if (text.isBlank()) "Tap to dictate…" else text, modifier = Modifier.fillMaxWidth())
        Button(onClick = {
            // v1: prefill demo text. The real path uses RemoteInput / dictation.
            text = "Spoken card"
        }, modifier = Modifier.fillMaxWidth()) { Text("Dictate") }
        Button(
            onClick = {
                if (text.isNotBlank()) {
                    scope.launch {
                        sharedRepo.upsert(Card(text = text.trim()))
                        AnalyticsService.shared.track(
                            AnalyticsEvent.CardCaptured(Surface.WATCH, CardKind.NOTE)
                        )
                        onDone()
                    }
                }
            },
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Save") }
    }
}
