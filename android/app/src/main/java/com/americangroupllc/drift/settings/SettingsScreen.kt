package com.americangroupllc.drift.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.americangroupllc.drift.core.obs.AnalyticsService

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    var analytics by remember { mutableStateOf(AnalyticsService.shared.optedIn) }
    var crash     by remember { mutableStateOf(false) }
    var invisible by remember { mutableStateOf(false) }
    var paused    by remember { mutableStateOf(false) }

    Scaffold(topBar = { CenterAlignedTopAppBar(title = { Text("Settings") }) }) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
        ) {
            ListItem(
                headlineContent = { Text("Invisible") },
                trailingContent = { Switch(checked = invisible, onCheckedChange = { invisible = it }) },
            )
            ListItem(
                headlineContent = { Text("Pause discoverability") },
                trailingContent = { Switch(checked = paused, onCheckedChange = { paused = it }) },
            )
            ListItem(
                headlineContent = { Text("Send crash reports") },
                trailingContent = { Switch(checked = crash, onCheckedChange = { crash = it }) },
            )
            ListItem(
                headlineContent = { Text("Send anonymous analytics") },
                trailingContent = { Switch(
                    checked = analytics,
                    onCheckedChange = { analytics = it; AnalyticsService.shared.optedIn = it },
                ) },
            )
        }
    }
}
