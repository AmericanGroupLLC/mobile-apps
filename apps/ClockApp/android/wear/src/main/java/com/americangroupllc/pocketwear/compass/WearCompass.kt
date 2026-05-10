package com.americangroupllc.pocketwear.compass

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.americangroupllc.pocket.core.compass.HeadingMath

@Composable
fun WearCompass(onSwipe: () -> Unit) {
    val ctx = LocalContext.current
    val heading by rememberWearHeading(ctx)
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(HeadingMath.cardinalLabel(heading), style = MaterialTheme.typography.display1)
        Text(String.format("%.0f°", heading), style = MaterialTheme.typography.title2)
        Spacer(Modifier.height(8.dp))
        Button(onClick = onSwipe) { Text("Next") }
    }
}

@Composable
private fun rememberWearHeading(ctx: Context): State<Double> {
    val state = remember { mutableStateOf(0.0) }
    DisposableEffect(ctx) {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val rotation = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val l = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val r = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(r, event.values)
                val o = FloatArray(3)
                SensorManager.getOrientation(r, o)
                state.value = HeadingMath.normalize(Math.toDegrees(o[0].toDouble()))
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }
        sm.registerListener(l, rotation, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(l) }
    }
    return state
}
