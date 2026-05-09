package com.americangroupllc.pocket.settings

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    var use24h by remember { mutableStateOf(false) }
    var crashOptIn by remember { mutableStateOf(false) }
    var analyticsOptIn by remember { mutableStateOf(false) }

    Scaffold(topBar = { TopAppBar(title = { Text("Settings") }) }) { padding ->
        Column(modifier = Modifier.padding(padding).fillMaxSize().padding(16.dp)) {
            ToggleRow("24-hour time", use24h) { use24h = it }
            ToggleRow("Crash reports (Sentry)", crashOptIn) { crashOptIn = it }
            ToggleRow("Anonymous analytics (PostHog)", analyticsOptIn) { analyticsOptIn = it }
            Spacer(Modifier.height(24.dp))
            Text("Pocket — five tools that disappear into the OS.", style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun ToggleRow(label: String, value: Boolean, onChange: (Boolean) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
        Text(label, modifier = Modifier.weight(1f))
        Switch(checked = value, onCheckedChange = onChange)
    }
}
