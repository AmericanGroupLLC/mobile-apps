package com.americangroupllc.clockwear

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Text
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

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("%02d:%02d".format(remaining / 60, remaining % 60), fontSize = 28.sp, fontWeight = FontWeight.Light)
        Spacer(Modifier.height(8.dp))
        if (!running) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Button(onClick = { totalSec = (totalSec - 5).coerceAtLeast(5); remaining = totalSec }) { Text("-", fontSize = 14.sp) }
                Text("${totalSec}s", fontSize = 12.sp)
                Button(onClick = { totalSec += 5; remaining = totalSec }) { Text("+", fontSize = 14.sp) }
            }
            Spacer(Modifier.height(8.dp))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = {
                if (!running && remaining == 0) remaining = totalSec
                running = !running
            }) { Text(if (running) "Pause" else "Start", fontSize = 12.sp) }
            Button(onClick = { running = false; remaining = totalSec }) { Text("Reset", fontSize = 12.sp) }
        }
    }
}
