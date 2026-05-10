package com.americangroupllc.buddyplay.games.racer

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import com.americangroupllc.buddyplay.core.domain.RacerPhysics
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun RacerCanvasComposable(vm: RacerViewModel) {
    Canvas(
        Modifier
            .fillMaxWidth()
            .aspectRatio((RacerPhysics.TRACK_WIDTH / RacerPhysics.TRACK_HEIGHT).toFloat())
    ) {
        val scaleX = size.width  / RacerPhysics.TRACK_WIDTH.toFloat()
        val scaleY = size.height / RacerPhysics.TRACK_HEIGHT.toFloat()

        drawRect(Color(0xFF0E1A2B), topLeft = Offset.Zero, size = size)

        for ((id, car) in vm.state.cars) {
            val isLocal = id == vm.localPlayerId
            val color = if (isLocal) Color(0xFFFF6F61) else Color.White
            val cx = (car.x * scaleX).toFloat()
            val cy = (car.y * scaleY).toFloat()
            drawCircle(color, radius = 6f, center = Offset(cx, cy))
            // Heading.
            val nx = (cx + cos(car.heading) * 12).toFloat()
            val ny = (cy + sin(car.heading) * 12).toFloat()
            drawLine(color, start = Offset(cx, cy), end = Offset(nx, ny), strokeWidth = 2f)
        }
    }
}
