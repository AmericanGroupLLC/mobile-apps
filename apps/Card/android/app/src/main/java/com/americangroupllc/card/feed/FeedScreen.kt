package com.americangroupllc.card.feed

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTag
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.americangroupllc.card.composer.ComposerView
import com.americangroupllc.card.core.models.Card

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedScreen(
    onOpenSettings: () -> Unit,
    vm: FeedViewModel = hiltViewModel(),
) {
    val cards by vm.cards.collectAsStateWithLifecycle()
    var draft by remember { mutableStateOf("") }
    var selected by remember { mutableStateOf<Card?>(null) }

    Scaffold(topBar = {
        TopAppBar(
            title = { Text("Card") },
            actions = {
                IconButton(onClick = onOpenSettings) {
                    Icon(Icons.Filled.Settings, contentDescription = "Settings")
                }
            }
        )
    }) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            ComposerView(
                text = draft,
                onTextChange = { draft = it },
                onSubmit = {
                    vm.capture(draft)
                    draft = ""
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp)
                    .semantics { testTag = "composer.field" }
            )
            HorizontalDivider()
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(0.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(cards, key = { it.id }) { card ->
                    CardRow(
                        card = card,
                        onTap = { selected = card },
                        onToggleComplete = { vm.toggleCompleted(card) },
                    )
                    HorizontalDivider()
                }
            }
        }
        selected?.let { c ->
            CardActionSheet(
                card = c,
                onDismiss = { selected = null },
                onConvert = { kind, at -> vm.convert(c, kind, at); selected = null },
                onToggleComplete = { vm.toggleCompleted(c); selected = null },
                onUpdate = { txt -> vm.update(c, txt); selected = null },
                onDelete = { vm.delete(c); selected = null },
            )
        }
    }
}
