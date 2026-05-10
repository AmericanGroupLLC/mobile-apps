package com.americangroupllc.driftwear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                MatchesList()
            }
        }
    }
}

@Composable
fun MatchesList() {
    val matches = listOf("Sara matched", "Maya waved")
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        if (matches.isEmpty()) {
            Text("No matches yet", style = MaterialTheme.typography.body2)
        } else {
            ScalingLazyColumn {
                items(matches) { m ->
                    Chip(
                        label = { Text(m) },
                        onClick = { /* navigate to QuickReply */ },
                        colors = ChipDefaults.primaryChipColors(),
                    )
                }
            }
        }
    }
}
