package com.americangroupllc.buddyplay.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PersonSearch
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.americangroupllc.buddyplay.core.models.GameKind

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen() {
    var lobbyTab by remember { mutableStateOf(LobbyTab.DUOPLAY) }
    var hostingKind by remember { mutableStateOf<GameKind?>(null) }
    var showJoin by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { CenterAlignedTopAppBar(title = { Text("BuddyPlay") }) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showJoin = true },
                icon = { Icon(Icons.Filled.PersonSearch, contentDescription = null) },
                text = { Text("Join Nearby Game") },
                containerColor = MaterialTheme.colorScheme.primary,
            )
        }
    ) { padding ->
        Column(Modifier.padding(padding).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            TabRow(selectedTabIndex = lobbyTab.ordinal) {
                LobbyTab.values().forEach { tab ->
                    Tab(
                        selected = lobbyTab == tab,
                        onClick = { lobbyTab = tab },
                        text = { Text(tab.label) }
                    )
                }
            }
            if (lobbyTab == LobbyTab.PARTY) {
                PartyDimmedCard()
            } else {
                CardScroller(onPick = { hostingKind = it })
                LastPlayedSection()
            }
        }
    }

    hostingKind?.let { kind ->
        // Phase 7 stub: opens a placeholder host lobby. Real lobby in Phase 8.
        AlertDialog(
            onDismissRequest = { hostingKind = null },
            title = { Text("Hosting ${kind.displayName}") },
            text  = { Text("Connectivity adapters land in Phase 8. The lobby flow + game screens are wired through Phase 9.") },
            confirmButton = { TextButton(onClick = { hostingKind = null }) { Text("OK") } }
        )
    }
    if (showJoin) {
        AlertDialog(
            onDismissRequest = { showJoin = false },
            title = { Text("Join Nearby") },
            text  = { Text("Scanning for nearby BuddyPlay phones — connectivity adapters land in Phase 8.") },
            confirmButton = { TextButton(onClick = { showJoin = false }) { Text("OK") } }
        )
    }
}

private enum class LobbyTab(val label: String) {
    ALL("All games"), DUOPLAY("DuoPlay (2P)"), PARTY("Party (3-4P)")
}

@Composable
private fun CardScroller(onPick: (GameKind) -> Unit) {
    Row(
        Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        GameKind.values().forEach { kind ->
            GameCard(kind, onPick)
        }
    }
}

@Composable
private fun GameCard(kind: GameKind, onPick: (GameKind) -> Unit) {
    Card(
        Modifier
            .size(width = 220.dp, height = 220.dp)
            .clickable { onPick(kind) },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = when (kind) {
                    GameKind.CHESS -> "♛"
                    GameKind.LUDO  -> "🎲"
                    GameKind.RACER -> "🚗"
                },
                fontSize = 36.sp
            )
            Text(kind.displayName, style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold))
            Text(
                text = when (kind) {
                    GameKind.CHESS -> "Turn-based · classic 8×8"
                    GameKind.LUDO  -> "Turn-based · DuoPlay"
                    GameKind.RACER -> "Real-time · Wi-Fi only"
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.weight(1f))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                val transports = if (kind.supportsBle) listOf("Wi-Fi", "Hotspot", "BLE")
                                 else listOf("Wi-Fi", "Hotspot")
                transports.forEach { t ->
                    AssistChip(onClick = {}, label = { Text(t) })
                }
            }
        }
    }
}

@Composable
private fun LastPlayedSection() {
    Column {
        Text("Last played", style = MaterialTheme.typography.titleSmall)
        Text(
            "No games yet — host one above or join a nearby friend.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PartyDimmedCard() {
    Card(
        Modifier.fillMaxWidth().heightIn(min = 160.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column(
            Modifier.fillMaxWidth().padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text("Party mode (3–4 players)", style = MaterialTheme.typography.titleMedium)
            Text("Coming in v1.1.", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
