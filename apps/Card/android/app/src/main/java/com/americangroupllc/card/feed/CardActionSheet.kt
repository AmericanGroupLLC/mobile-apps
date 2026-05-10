package com.americangroupllc.card.feed

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardActionSheet(
    card: Card,
    onDismiss: () -> Unit,
    onConvert: (CardKind, Long?) -> Unit,
    onToggleComplete: () -> Unit,
    onUpdate: (String) -> Unit,
    onDelete: () -> Unit,
) {
    var editing by remember { mutableStateOf(false) }
    var draft by remember { mutableStateOf(card.text) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(modifier = Modifier.padding(16.dp)) {
            if (editing) {
                OutlinedTextField(
                    value = draft, onValueChange = { draft = it },
                    label = { Text("Card text") },
                    modifier = Modifier.fillMaxWidth(),
                )
                Button(onClick = { onUpdate(draft) }, modifier = Modifier.padding(top = 8.dp)) {
                    Text("Save")
                }
            } else {
                Text(card.text, modifier = Modifier.padding(bottom = 12.dp))
                HorizontalDivider()
                Button(onClick = { onConvert(CardKind.TASK, null) }, modifier = Modifier.padding(top = 8.dp).fillMaxWidth()) {
                    Text("Mark as task")
                }
                Button(
                    onClick = {
                        // 1-hour-from-now reminder; UI in v1 keeps it simple,
                        // a richer date picker is wired in CardActionSheet later.
                        onConvert(CardKind.REMINDER, System.currentTimeMillis() + 60L * 60L * 1000L)
                    },
                    modifier = Modifier.padding(top = 8.dp).fillMaxWidth()
                ) { Text("Set reminder (1 hour)") }
                if (card.kind != CardKind.NOTE) {
                    TextButton(onClick = { onConvert(CardKind.NOTE, null) }, modifier = Modifier.padding(top = 8.dp)) {
                        Text("Convert to plain note")
                    }
                }
                if (card.kind == CardKind.TASK) {
                    TextButton(onClick = onToggleComplete, modifier = Modifier.padding(top = 8.dp)) {
                        Text(if (card.isCompleted) "Mark not done" else "Mark done")
                    }
                }
                TextButton(onClick = { editing = true }, modifier = Modifier.padding(top = 8.dp)) {
                    Text("Edit text")
                }
                TextButton(onClick = onDelete, modifier = Modifier.padding(top = 8.dp)) {
                    Text("Delete")
                }
            }
        }
    }
}
