package com.americangroupllc.drift.chat

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.drift.core.models.Message
import com.americangroupllc.drift.core.models.ReplySuggestion
import com.americangroupllc.drift.core.models.Tone

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(conversationId: String) {
    var draft by remember { mutableStateOf("") }
    val messages = remember { listOf<Message>() }
    val suggestions = remember<ReplySuggestion?> {
        ReplySuggestion(
            casual  = "Hey — how's your week going?",
            context = "Saw your books vibe — what are you reading?",
            playful = "Pick a fight: best pizza topping?",
            tone    = Tone.SLOW,
        )
    }

    Scaffold(topBar = { CenterAlignedTopAppBar(title = { Text("Chat") }) }) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(horizontal = 12.dp)
        ) {
            LazyColumn(Modifier.weight(1f)) {
                items(messages) { m -> MessageBubble(m, isMine = false) }
            }

            // Reply suggestions row
            Row(
                Modifier
                    .horizontalScroll(rememberScrollState())
                    .padding(vertical = 8.dp)
            ) {
                suggestions?.let {
                    suggestionPill("Casual",  it.casual)  { draft = it.casual }
                    Spacer(Modifier.width(8.dp))
                    suggestionPill("Context", it.context) { draft = it.context }
                    Spacer(Modifier.width(8.dp))
                    suggestionPill("Playful", it.playful) { draft = it.playful }
                }
            }

            Row(Modifier.fillMaxWidth().padding(bottom = 12.dp)) {
                OutlinedTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    placeholder = { Text("Message") },
                    modifier = Modifier.weight(1f),
                )
                Spacer(Modifier.width(8.dp))
                Button(onClick = { /* send */ }, enabled = draft.isNotBlank()) { Text("Send") }
            }
        }
    }
}

@Composable
private fun suggestionPill(label: String, text: String, onClick: () -> Unit) {
    Card(modifier = Modifier.padding(end = 4.dp).widthClampForChat()) {
        androidx.compose.foundation.layout.Box(modifier = Modifier.padding(8.dp)) {
            Column {
                Text(label, style = MaterialTheme.typography.labelSmall)
                Text(text, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun Modifier.widthClampForChat() = this.then(Modifier.width(180.dp))

@Composable
fun MessageBubble(m: Message, isMine: Boolean) {
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        if (isMine) Spacer(Modifier.weight(1f))
        Card { Text(m.text, modifier = Modifier.padding(10.dp)) }
        if (!isMine) Spacer(Modifier.weight(1f))
    }
}
