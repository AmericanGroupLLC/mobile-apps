package com.americangroupllc.pocketwear

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import kotlinx.coroutines.delay

@Composable
fun StopwatchScreen() {
    var elapsedMs by remember { mutableStateOf(0L) }
    var running by remember { mutableStateOf(false) }
    LaunchedEffect(running) {
        var last = System.currentTimeMillis()
        while (running) {
            delay(50)
            val n = System.currentTimeMillis()
            elapsedMs += n - last
            last = n
        }
    }
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(format(elapsedMs), fontSize = 24.sp, fontWeight = FontWeight.Light)
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(
                onClick = { running = !running },
                colors = ButtonDefaults.primaryButtonColors(
                    backgroundColor = if (running) MaterialTheme.colors.error else MaterialTheme.colors.primary
                )
            ) { Text(if (running) "Stop" else "Start", fontSize = 12.sp) }
            Button(onClick = { running = false; elapsedMs = 0 }) {
                Text("Reset", fontSize = 12.sp)
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
