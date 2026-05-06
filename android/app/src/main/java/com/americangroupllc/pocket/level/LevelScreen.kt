package com.americangroupllc.pocket.level

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.americangroupllc.pocket.core.level.LevelMath
import kotlin.math.abs

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LevelScreen() {
    val ctx = LocalContext.current
    val pr by rememberPitchRoll(ctx)
    Scaffold(topBar = { TopAppBar(title = { Text("Level") }) }) { padding ->
        Column(
            modifier = Modifier.padding(padding).fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Canvas(modifier = Modifier.size(280.dp)) {
                val r = size.minDimension / 2
                drawCircle(Color.Gray, radius = r, style = Stroke(2f))
                drawCircle(Color.LightGray, radius = r / 2, style = Stroke(1f))
                val (ox, oy) = LevelMath.bubbleOffset(pr.first, pr.second, r.toDouble())
                val flat = abs(pr.first) < 1.0 && abs(pr.second) < 1.0
                drawCircle(
                    color = if (flat) Color.Green else Color(0xFFFFC107),
                    radius = r * 0.12f,
                    center = Offset(size.width / 2 + ox.toFloat(), size.height / 2 + oy.toFloat())
                )
            }
            Spacer(Modifier.height(24.dp))
            Text(String.format("Pitch %.1f° · Roll %.1f°", pr.first, pr.second))
        }
    }
}

@Composable
private fun rememberPitchRoll(ctx: Context): State<Pair<Double, Double>> {
    val state = remember { mutableStateOf(0.0 to 0.0) }
    DisposableEffect(ctx) {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val gravity = sm.getDefaultSensor(Sensor.TYPE_GRAVITY)
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (event.sensor.type == Sensor.TYPE_GRAVITY) {
                    val gx = event.values[0].toDouble() / 9.81
                    val gy = event.values[1].toDouble() / 9.81
                    val gz = event.values[2].toDouble() / 9.81
                    val pr = LevelMath.pitchRoll(gx, gy, gz)
                    state.value = pr.pitchDegrees to pr.rollDegrees
                }
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }
        sm.registerListener(listener, gravity, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(listener) }
    }
    return state
}
