package com.americangroupllc.clockapp

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun StopwatchScreen() {
    var elapsedMs by remember { mutableStateOf(0L) }
    var running by remember { mutableStateOf(false) }
    var laps by remember { mutableStateOf<List<Long>>(emptyList()) }

    LaunchedEffect(running) {
        var last = System.currentTimeMillis()
        while (running) {
            delay(16)
            val now = System.currentTimeMillis()
            elapsedMs += now - last
            last = now
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(40.dp))
        Text(format(elapsedMs), fontSize = 56.sp, fontWeight = FontWeight.Light)
        Spacer(Modifier.height(24.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
            OutlinedButton(onClick = {
                if (running) laps = listOf(elapsedMs) + laps else { elapsedMs = 0; laps = emptyList() }
            }) { Text(if (running) "Lap" else "Reset") }
            Button(onClick = { running = !running },
                colors = ButtonDefaults.buttonColors(containerColor = if (running) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary)) {
                Text(if (running) "Stop" else "Start")
            }
        }
        Spacer(Modifier.height(24.dp))
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            itemsIndexed(laps) { i, lap ->
                Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Lap ${laps.size - i}")
                    Text(format(lap))
                }
                HorizontalDivider()
            }
        }
    }
}

private fun format(ms: Long): String {
    val totalCs = ms / 10
    val cs = totalCs % 100
    val s = (totalCs / 100) % 60
    val m = totalCs / 6000
    return "%02d:%02d.%02d".format(m, s, cs)
}
