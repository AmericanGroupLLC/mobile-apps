package com.americangroupllc.buddyplay.games.chess

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.sp
import com.americangroupllc.buddyplay.core.domain.ChessColor
import com.americangroupllc.buddyplay.core.domain.ChessPiece
import com.americangroupllc.buddyplay.core.domain.ChessPieceKind
import com.americangroupllc.buddyplay.core.domain.ChessSquare

@Composable
fun ChessBoardComposable(vm: ChessViewModel) {
    val light = Color(0xFFEDD9B6)
    val dark  = Color(0xFF8C5A33)
    val highlight = Color(0xFFFF6F61).copy(alpha = 0.55f)
    val measurer = rememberTextMeasurer()

    Canvas(
        Modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    val cell = size.width / 8f
                    val file = (offset.x / cell).toInt().coerceIn(0, 7)
                    val rankFromTop = (offset.y / cell).toInt().coerceIn(0, 7)
                    val rank = 7 - rankFromTop
                    vm.tap(ChessSquare(file, rank))
                }
            }
    ) {
        val cell = size.width / 8f
        for (rank in 0..7) {
            for (file in 0..7) {
                val sq = ChessSquare(file, 7 - rank)
                val isLight = (file + rank) % 2 == 0
                val color = if (isLight) light else dark
                drawRect(color, topLeft = Offset(file * cell, rank * cell), size = Size(cell, cell))
                if (vm.selected == sq) {
                    drawRect(highlight, topLeft = Offset(file * cell, rank * cell), size = Size(cell, cell))
                } else if (sq in vm.legalDestinations) {
                    drawCircle(highlight,
                        radius = cell * 0.20f,
                        center = Offset(file * cell + cell / 2, rank * cell + cell / 2))
                }
                vm.state.board[sq]?.let { piece ->
                    val symbol = symbol(piece)
                    val style = TextStyle(fontSize = (cell * 0.7f).sp.value.sp,
                        color = if (piece.color == ChessColor.WHITE) Color.White else Color.Black)
                    val tl = measurer.measure(symbol, style)
                    drawText(tl,
                        topLeft = Offset(
                            file * cell + (cell - tl.size.width) / 2,
                            rank * cell + (cell - tl.size.height) / 2
                        ))
                }
                drawRect(Color.Black.copy(alpha = 0.05f),
                    topLeft = Offset(file * cell, rank * cell),
                    size = Size(cell, cell), style = Stroke(width = 1f))
            }
        }
    }
}

private fun symbol(piece: ChessPiece): String = when (piece.kind) {
    ChessPieceKind.KING   -> "♚"
    ChessPieceKind.QUEEN  -> "♛"
    ChessPieceKind.ROOK   -> "♜"
    ChessPieceKind.BISHOP -> "♝"
    ChessPieceKind.KNIGHT -> "♞"
    ChessPieceKind.PAWN   -> "♟"
}
