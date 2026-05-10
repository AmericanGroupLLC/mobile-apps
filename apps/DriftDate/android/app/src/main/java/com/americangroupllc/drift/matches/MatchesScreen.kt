package com.americangroupllc.drift.matches

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
import com.americangroupllc.drift.core.models.Wave

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MatchesScreen() {
    val matches = remember { listOf<Wave>() }
    Scaffold(topBar = { CenterAlignedTopAppBar(title = { Text("Matches") }) }) { padding ->
        if (matches.isEmpty()) {
            Text(
                "No matches yet",
                Modifier
                    .padding(padding)
                    .fillMaxSize()
                    .padding(16.dp)
            )
        } else {
            LazyColumn(Modifier.padding(padding)) {
                items(matches) { w ->
                    ListItem(
                        headlineContent = { Text("Matched in ${w.layer.name.lowercase()}") },
                        supportingContent = { Text(w.matchedAt ?: "—") },
                    )
                }
            }
        }
    }
}
