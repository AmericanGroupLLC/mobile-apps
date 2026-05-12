package com.myhealth.app.ui.workout

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.app.ui.theme.CarePlusColor

/**
 * Apple-style activity rings (Move / Exercise / Stand). Pure Compose
 * Canvas — no native deps. Reads from Health Connect once that's wired
 * (today the values are placeholders).
 */
@Composable
fun ActivityRings(
    move: Float,
    exercise: Float,
    stand: Float,
    diameterDp: Int = 180,
    lineWidthDp: Int = 14,
    ringStepDp: Int = 22,
) {
    Box(
        modifier = Modifier.size(diameterDp.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.size(diameterDp.dp)) {
            val stroke = lineWidthDp.dp.toPx()
            drawRing(0, ringStepDp.dp.toPx(), CarePlusColor.WorkoutPink, move, stroke)
            drawRing(1, ringStepDp.dp.toPx(), CarePlusColor.TrainGreen, exercise, stroke)
            drawRing(2, ringStepDp.dp.toPx(), CarePlusColor.CareBlue, stand, stroke)
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawRing(
    index: Int, step: Float, color: Color, progress: Float, stroke: Float,
) {
    val pad = step * index + stroke / 2
    val arcSize = Size(size.width - pad * 2, size.height - pad * 2)
    val topLeft = Offset(pad, pad)
    drawArc(
        color = color.copy(alpha = 0.18f),
        startAngle = -90f,
        sweepAngle = 360f,
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = stroke, cap = StrokeCap.Round)
    )
    drawArc(
        color = color,
        startAngle = -90f,
        sweepAngle = 360f * progress.coerceIn(0f, 1f),
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = stroke, cap = StrokeCap.Round)
    )
}

/** Three-column ring-stat strip used under the rings on Workout home. */
@Composable
fun ActivityRingsStats(move: String, exercise: String, stand: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Move", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
            Text(move, fontWeight = FontWeight.Bold)
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Exercise", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
            Text(exercise, fontWeight = FontWeight.Bold)
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Stand", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
            Text(stand, fontWeight = FontWeight.Bold)
        }
    }
}
