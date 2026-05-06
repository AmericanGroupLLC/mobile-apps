package com.americangroupllc.buddyplay.lobby

import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Join lobby. Auto-scans every ~5 s while foregrounded. */
@Composable
fun JoinLobbyScreen() {
    Column(
        Modifier.fillMaxSize().padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(0.2f))
        Text("Scanning for nearby BuddyPlay phones…", style = MaterialTheme.typography.titleMedium)
        Text(
            "Make sure both phones are on the same Wi-Fi (or that one is hosting a Mobile Hotspot the other has joined).",
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.weight(1f))
    }
}
