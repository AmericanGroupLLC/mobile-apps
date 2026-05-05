package com.americangroupllc.clockapp

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun ClockScreen() {
    var now by remember { mutableStateOf(Date()) }
    LaunchedEffect(Unit) {
        while (true) { now = Date(); delay(1_000) }
    }
    val timeFmt = remember { SimpleDateFormat("HH:mm:ss", Locale.getDefault()) }
    val dateFmt = remember { SimpleDateFormat("EEEE, MMM d", Locale.getDefault()) }

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(timeFmt.format(now), fontSize = 64.sp, fontWeight = FontWeight.Light)
        Spacer(Modifier.height(8.dp))
        Text(dateFmt.format(now), color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(32.dp))
        AnalogClock(date = now, modifier = Modifier.size(220.dp))
    }
}

@Composable
fun AnalogClock(date: Date, modifier: Modifier = Modifier) {
    val color = MaterialTheme.colorScheme.onSurface
    val accent = MaterialTheme.colorScheme.error
    val cal = remember(date) { Calendar.getInstance().apply { time = date } }
    val h = cal.get(Calendar.HOUR)
    val m = cal.get(Calendar.MINUTE)
    val s = cal.get(Calendar.SECOND)

    Canvas(modifier = modifier) {
        val r = size.minDimension / 2f
        val center = Offset(size.width / 2f, size.height / 2f)
        drawCircle(color = color, radius = r, style = Stroke(width = 4f), center = center)
        for (i in 0 until 12) {
            rotate(i * 30f, pivot = center) {
                drawLine(color = color, start = Offset(center.x, center.y - r + 4f),
                    end = Offset(center.x, center.y - r + 16f), strokeWidth = 3f)
            }
        }
        fun hand(angleDeg: Float, length: Float, width: Float, c: Color) {
            rotate(angleDeg, pivot = center) {
                drawLine(color = c, start = center,
                    end = Offset(center.x, center.y - length), strokeWidth = width)
            }
        }
        hand((h + m / 60f) * 30f, r * 0.55f, 8f, color)
        hand(m * 6f, r * 0.75f, 5f, color)
        hand(s * 6f, r * 0.85f, 2f, accent)
    }
}
