package com.americangroupllc.buddyplay.games.ludo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun LudoBoardComposable(vm: LudoViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        playerLane(vm = vm, peer = vm.host, color = Color(0xFFE63946), label = vm.host.displayName)
        playerLane(vm = vm, peer = vm.guest, color = Color(0xFF457B9D), label = vm.guest.displayName)
    }
}

@Composable
private fun playerLane(vm: LudoViewModel, peer: com.americangroupllc.buddyplay.core.models.Peer, color: Color, label: String) {
    Column(
        Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(12.dp).clip(CircleShape).background(color)
            )
            Spacer(Modifier.width(8.dp))
            Text(label, style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.weight(1f))
            val target = if (peer.id == vm.host.id) 105 else 205
            val home = vm.state.tokens[peer.id]?.count { it == target } ?: 0
            Text("$home / 4 home", style = MaterialTheme.typography.labelSmall)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (idx in 0..3) {
                val pos = vm.state.tokens[peer.id]?.get(idx) ?: -1
                val isLegal = peer.id == vm.state.sideToMove && idx in vm.legalTokenIndices
                tokenChip(pos = pos, color = color, isLegal = isLegal,
                    onClick = { if (isLegal) vm.moveToken(idx) })
            }
        }
    }
}

@Composable
private fun tokenChip(pos: Int, color: Color, isLegal: Boolean, onClick: () -> Unit) {
    Column(
        Modifier.width(64.dp).clickable(enabled = isLegal, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Box(
            Modifier
                .size(32.dp).clip(CircleShape).background(color)
                .border(width = 3.dp, color = if (isLegal) MaterialTheme.colorScheme.primary else Color.Transparent, shape = CircleShape)
        )
        Text(label(pos), style = MaterialTheme.typography.labelSmall)
    }
}

private fun label(pos: Int): String = when (pos) {
    -1 -> "Base"
    in 100..105, in 200..205 -> "Home"
    else -> "Sq $pos"
}
