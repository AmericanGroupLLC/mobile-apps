package com.americangroupllc.pocket.compass

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
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.americangroupllc.pocket.core.compass.HeadingMath
import kotlin.math.cos
import kotlin.math.sin

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CompassScreen() {
    val ctx = LocalContext.current
    val heading by rememberHeading(ctx)

    Scaffold(topBar = { TopAppBar(title = { Text("Compass") }) }) { padding ->
        Column(
            modifier = Modifier.padding(padding).fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(HeadingMath.cardinalLabel(heading), style = MaterialTheme.typography.headlineLarge)
            Spacer(Modifier.height(16.dp))
            Canvas(modifier = Modifier.size(280.dp)) {
                val r = size.minDimension / 2
                drawCircle(Color.Gray, radius = r, style = Stroke(2f))
                rotate(degrees = -heading.toFloat()) {
                    val tip = Offset(size.width / 2, size.height / 2 - r * 0.85f)
                    drawLine(Color.Red, Offset(size.width / 2, size.height / 2), tip, strokeWidth = 6f)
                }
            }
            Text(String.format("%.0f°", heading), style = MaterialTheme.typography.titleMedium)
        }
    }
}

@Composable
private fun rememberHeading(ctx: Context): State<Double> {
    val state = remember { mutableStateOf(0.0) }
    DisposableEffect(ctx) {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val rotationVector = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
                    val r = FloatArray(9)
                    SensorManager.getRotationMatrixFromVector(r, event.values)
                    val orient = FloatArray(3)
                    SensorManager.getOrientation(r, orient)
                    val az = Math.toDegrees(orient[0].toDouble())
                    state.value = HeadingMath.normalize(az)
                }
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }
        sm.registerListener(listener, rotationVector, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(listener) }
    }
    return state
}
