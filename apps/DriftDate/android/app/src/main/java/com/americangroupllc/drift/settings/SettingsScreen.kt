package com.americangroupllc.drift.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.americangroupllc.drift.core.obs.AnalyticsService
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onAccountErased: () -> Unit = {},
) {
    var analytics by remember { mutableStateOf(AnalyticsService.shared.optedIn) }
    var crash     by remember { mutableStateOf(false) }
    var invisible by remember { mutableStateOf(false) }
    var paused    by remember { mutableStateOf(false) }

    var showEraseDialog by remember { mutableStateOf(false) }
    var erasing         by remember { mutableStateOf(false) }
    var eraseError      by remember { mutableStateOf<String?>(null) }

    val context = LocalContext.current
    val scope   = rememberCoroutineScope()

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

            HorizontalDivider()

            // Mirrors iOS Settings → Account → "Erase all data"
            // (ios/Drift/Features/Settings/SettingsScreen.swift). Calls the
            // wipe-me Supabase Edge Function with the user's JWT, then
            // clears local storage and bounces back to onboarding.
            ListItem(
                headlineContent = {
                    Text(
                        "Erase all data",
                        color = MaterialTheme.colorScheme.error,
                    )
                },
                supportingContent = {
                    Text("Permanently delete your account and every Drift profile, photo, wave, and message.")
                },
                modifier = Modifier.clickable(enabled = !erasing) { showEraseDialog = true },
            )

            eraseError?.let { msg ->
                Text(
                    text = msg,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(16.dp),
                )
            }
        }
    }

    if (showEraseDialog) {
        AlertDialog(
            onDismissRequest = { if (!erasing) showEraseDialog = false },
            title  = { Text("Erase all data?") },
            text   = { Text("This permanently deletes your account and all data. Continue?") },
            confirmButton = {
                TextButton(
                    enabled = !erasing,
                    onClick = {
                        erasing = true
                        eraseError = null
                        scope.launch {
                            val result = AccountWipe.wipe(context.applicationContext)
                            erasing = false
                            if (result.isSuccess) {
                                showEraseDialog = false
                                onAccountErased()
                            } else {
                                eraseError = result.exceptionOrNull()?.message
                                    ?: "Erase failed; please try again."
                            }
                        }
                    },
                ) { Text("Delete", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(enabled = !erasing, onClick = { showEraseDialog = false }) {
                    Text("Cancel")
                }
            },
        )
    }
}
