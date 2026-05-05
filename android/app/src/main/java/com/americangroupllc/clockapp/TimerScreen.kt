package com.americangroupllc.clockapp

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun TimerScreen() {
    var totalSec by remember { mutableStateOf(60) }
    var remaining by remember { mutableStateOf(60) }
    var running by remember { mutableStateOf(false) }

    LaunchedEffect(running) {
        while (running && remaining > 0) {
            delay(1_000)
            remaining -= 1
            if (remaining == 0) running = false
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(40.dp))
        Text("%02d:%02d".format(remaining / 60, remaining % 60), fontSize = 72.sp, fontWeight = FontWeight.Light)
        Spacer(Modifier.height(24.dp))
        if (!running) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = { totalSec = (totalSec - 5).coerceAtLeast(5); remaining = totalSec }) { Text("-5s") }
                Text("Set: ${totalSec}s")
                OutlinedButton(onClick = { totalSec += 5; remaining = totalSec }) { Text("+5s") }
            }
            Spacer(Modifier.height(24.dp))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
            OutlinedButton(onClick = { running = false; remaining = totalSec }) { Text("Reset") }
            Button(onClick = {
                if (!running && remaining == 0) remaining = totalSec
                running = !running
            }) { Text(if (running) "Pause" else "Start") }
        }
    }
}
