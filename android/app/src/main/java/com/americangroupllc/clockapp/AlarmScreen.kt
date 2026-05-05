package com.americangroupllc.clockapp

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

private data class Alarm(val id: Int, var hour: Int, var minute: Int, var enabled: Boolean)

@Composable
fun AlarmScreen() {
    var alarms by remember { mutableStateOf<List<Alarm>>(emptyList()) }
    var nextId by remember { mutableStateOf(1) }
    var showAdd by remember { mutableStateOf(false) }
    val fmt = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }

    Scaffold(floatingActionButton = {
        FloatingActionButton(onClick = { showAdd = true }) { Text("+") }
    }) { p ->
        LazyColumn(modifier = Modifier.padding(p).fillMaxSize()) {
            items(alarms, key = { it.id }) { a ->
                ListItem(
                    headlineContent = {
                        val cal = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY, a.hour); set(Calendar.MINUTE, a.minute) }
                        Text(fmt.format(cal.time), style = MaterialTheme.typography.headlineMedium)
                    },
                    trailingContent = {
                        Switch(checked = a.enabled, onCheckedChange = { v ->
                            alarms = alarms.map { if (it.id == a.id) it.copy(enabled = v) else it }
                        })
                    },
                )
                HorizontalDivider()
            }
        }
    }

    if (showAdd) {
        var hour by remember { mutableStateOf(7) }
        var minute by remember { mutableStateOf(0) }
        AlertDialog(
            onDismissRequest = { showAdd = false },
            confirmButton = {
                TextButton(onClick = {
                    alarms = alarms + Alarm(nextId++, hour, minute, true)
                    showAdd = false
                }) { Text("Save") }
            },
            dismissButton = { TextButton(onClick = { showAdd = false }) { Text("Cancel") } },
            title = { Text("New alarm") },
            text = {
                Column {
                    OutlinedTextField(value = hour.toString(), onValueChange = { hour = it.toIntOrNull()?.coerceIn(0, 23) ?: hour }, label = { Text("Hour (0-23)") })
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(value = minute.toString(), onValueChange = { minute = it.toIntOrNull()?.coerceIn(0, 59) ?: minute }, label = { Text("Minute (0-59)") })
                }
            }
        )
    }
}
