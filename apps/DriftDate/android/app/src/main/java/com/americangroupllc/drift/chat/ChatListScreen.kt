package com.americangroupllc.drift.chat

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.drift.core.models.Conversation

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatListScreen(onOpen: (String) -> Unit) {
    val convos = remember { listOf<Conversation>() }
    Scaffold(topBar = { CenterAlignedTopAppBar(title = { Text("Chats") }) }) { padding ->
        LazyColumn(
            Modifier
                .padding(padding)
                .fillMaxSize()
        ) {
            items(convos) { c ->
                ListItem(
                    headlineContent = { Text("Conversation") },
                    supportingContent = { Text(c.tone.name.lowercase()) },
                    modifier = Modifier.padding(8.dp),
                )
            }
        }
    }
}
