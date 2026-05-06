package com.americangroupllc.pocketwear.level

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Text
import com.americangroupllc.pocket.core.level.LevelMath
import kotlin.math.abs

@Composable
fun WearLevel(onSwipe: () -> Unit) {
    val ctx = LocalContext.current
    val pr by rememberWearPitchRoll(ctx)
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Canvas(modifier = Modifier.size(120.dp)) {
            val r = size.minDimension / 2
            drawCircle(Color.Gray, radius = r, style = Stroke(2f))
            val (ox, oy) = LevelMath.bubbleOffset(pr.first, pr.second, r.toDouble())
            val flat = abs(pr.first) < 1 && abs(pr.second) < 1
            drawCircle(
                color = if (flat) Color.Green else Color(0xFFFFC107),
                radius = r * 0.16f,
                center = Offset(size.width / 2 + ox.toFloat(), size.height / 2 + oy.toFloat())
            )
        }
        Spacer(Modifier.height(8.dp))
        Button(onClick = onSwipe) { Text("Next") }
    }
}

@Composable
private fun rememberWearPitchRoll(ctx: Context): State<Pair<Double, Double>> {
    val state = remember { mutableStateOf(0.0 to 0.0) }
    DisposableEffect(ctx) {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val gravity = sm.getDefaultSensor(Sensor.TYPE_GRAVITY)
        val l = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val pr = LevelMath.pitchRoll(
                    event.values[0].toDouble() / 9.81,
                    event.values[1].toDouble() / 9.81,
                    event.values[2].toDouble() / 9.81
                )
                state.value = pr.pitchDegrees to pr.rollDegrees
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }
        sm.registerListener(l, gravity, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(l) }
    }
    return state
}
