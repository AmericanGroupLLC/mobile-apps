package com.americangroupllc.card.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    vm: SettingsViewModel = hiltViewModel(),
) {
    val state by vm.state.collectAsStateWithLifecycle()
    Scaffold(topBar = {
        TopAppBar(
            title = { Text("Settings") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
            }
        )
    }) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            ListItem(
                headlineContent = { Text("Use 24-hour time") },
                trailingContent = {
                    Switch(checked = state.use24Hour, onCheckedChange = vm::setUse24Hour)
                }
            )
            HorizontalDivider()
            ListItem(
                headlineContent = { Text("Send crash reports") },
                supportingContent = { Text("Off by default. Opt in to help fix crashes.") },
                trailingContent = {
                    Switch(checked = state.crashOptedIn, onCheckedChange = vm::setCrashOptedIn)
                }
            )
            ListItem(
                headlineContent = { Text("Send anonymous usage data") },
                supportingContent = { Text("Off by default. Opt in to help shape Card.") },
                trailingContent = {
                    Switch(checked = state.analyticsOptedIn, onCheckedChange = vm::setAnalyticsOptedIn)
                }
            )
        }
    }
}
