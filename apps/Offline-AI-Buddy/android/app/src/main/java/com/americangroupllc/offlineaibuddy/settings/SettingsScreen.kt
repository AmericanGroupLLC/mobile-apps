package com.americangroupllc.offlineaibuddy.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun SettingsScreen() {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        item { ListItem(headlineContent = { Text("Default language") }) }
        item { ListItem(headlineContent = { Text("Voice settings") }) }
        item { ListItem(headlineContent = { Text("Wi-Fi-only model downloads") }, trailingContent = { Text("On") }) }
        item { ListItem(headlineContent = { Text("Theme") }, supportingContent = { Text("System") }) }
        item { ListItem(headlineContent = { Text("Premium / Subscribe / Restore") }) }
        item { ListItem(headlineContent = { Text("Erase all chats") }) }
        item { ListItem(headlineContent = { Text("Delete model") }) }
        item {
            ListItem(
                headlineContent = { Text("Privacy") },
                supportingContent = { Text("Offline AI Buddy does not send any data to us.") },
            )
        }
    }
}
