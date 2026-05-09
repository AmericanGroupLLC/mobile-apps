package com.americangroupllc.card.composer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.lifecycle.lifecycleScope
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.obs.AnalyticsEvent
import com.americangroupllc.card.core.obs.AnalyticsService
import com.americangroupllc.card.core.obs.Surface as CaptureSurface
import com.americangroupllc.card.core.models.CardKind
import com.americangroupllc.card.core.storage.CardRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Single-screen voice/text composer launched by the Quick Settings tile.
 * Saves directly to the Room repo and finishes — never returns to a feed.
 */
@AndroidEntryPoint
class QuickCaptureActivity : ComponentActivity() {

    @Inject lateinit var repo: CardRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize().padding(24.dp)) {
                    QuickCaptureUI(
                        onSave = { text ->
                            val trimmed = text.trim()
                            if (trimmed.isEmpty()) { finish(); return@QuickCaptureUI }
                            lifecycleScope.launch {
                                repo.upsert(Card(text = trimmed))
                                AnalyticsService.shared.track(
                                    AnalyticsEvent.CardCaptured(CaptureSurface.TILE, CardKind.NOTE)
                                )
                                finish()
                            }
                        },
                        onCancel = { finish() },
                    )
                }
            }
        }
    }
}

@Composable
private fun QuickCaptureUI(onSave: (String) -> Unit, onCancel: () -> Unit) {
    var text by remember { mutableStateOf("") }
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier
            .fillMaxSize()
            .wrapContentHeight(Alignment.CenterVertically),
    ) {
        Text("Capture", style = MaterialTheme.typography.headlineSmall)
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            placeholder = { Text("Speak or type…") },
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { onSave(text) }),
            modifier = Modifier.fillMaxSize().wrapContentHeight(),
        )
        Button(onClick = { onSave(text) }) { Text("Save") }
        TextButton(onClick = onCancel) { Text("Cancel") }
    }
}
