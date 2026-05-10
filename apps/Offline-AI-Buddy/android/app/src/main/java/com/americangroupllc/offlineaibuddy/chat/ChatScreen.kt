package com.americangroupllc.offlineaibuddy.chat

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.americangroupllc.offlineaibuddy.core.models.ChatMessage
import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language

@Composable
fun ChatScreen(kind: ChatSession.Kind, vm: ChatViewModel = hiltViewModel()) {
    val messages by vm.messages.collectAsState()
    val streaming by vm.streamingText.collectAsState()
    var input by remember { mutableStateOf("") }
    Column(modifier = Modifier.fillMaxSize().padding(8.dp)) {
        LazyColumn(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            items(messages, key = { it.id }) { m -> Bubble(m) }
            if (streaming.isNotEmpty()) {
                item {
                    Bubble(ChatMessage(id = "streaming", role = ChatMessage.Role.ASSISTANT, text = streaming))
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Message…") },
            )
            IconButton(
                enabled = input.isNotBlank(),
                onClick = {
                    val text = input
                    input = ""
                    vm.send(kind, Language.EN, isKidSafe = false, text)
                },
            ) { Icon(Icons.Filled.Send, contentDescription = "Send") }
        }
    }
}

@Composable
private fun Bubble(m: ChatMessage) {
    Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp)) {
        Card {
            Text(m.text, modifier = Modifier.padding(10.dp))
        }
    }
}
