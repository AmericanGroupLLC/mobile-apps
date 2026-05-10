package com.americangroupllc.buddyplay.games.racer

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.americangroupllc.buddyplay.core.models.Peer
import com.americangroupllc.buddyplay.core.models.Transport

@Composable
fun RacerScreen(host: Peer, guest: Peer, localPlayerId: String, transport: Transport) {
    val vm = remember { RacerViewModel(host, guest, localPlayerId, transport) }

    DisposableEffect(Unit) {
        vm.startTicking()
        onDispose { vm.stopTicking() }
    }

    Column(
        Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        vm.rejectMessage?.let { msg ->
            Column(
                Modifier.fillMaxWidth().padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Icon(Icons.Filled.WifiOff, contentDescription = null)
                Text("Mini Racer needs Wi-Fi or Hotspot", style = MaterialTheme.typography.titleMedium)
                Text(msg, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            return@Column
        }

        RacerCanvasComposable(vm)
        Spacer(Modifier.weight(1f))

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                holdButton(Icons.Filled.ArrowBack, onPress = { vm.setSteering(-1.0) }, onRelease = { vm.setSteering(0.0) })
                holdButton(Icons.Filled.ArrowForward, onPress = { vm.setSteering(1.0) }, onRelease = { vm.setSteering(0.0) })
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                holdButton(Icons.Filled.ArrowUpward, onPress = { vm.setThrottle(1.0) }, onRelease = { vm.setThrottle(0.0) })
                holdButton(Icons.Filled.Stop, onPress = { vm.setBrake(1.0) }, onRelease = { vm.setBrake(0.0) })
            }
        }
    }
}

@Composable
private fun holdButton(icon: androidx.compose.ui.graphics.vector.ImageVector, onPress: () -> Unit, onRelease: () -> Unit) {
    IconButton(
        onClick = {},
        modifier = Modifier
            .size(64.dp)
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        onPress()
                        try { tryAwaitRelease() } finally { onRelease() }
                    }
                )
            }
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(48.dp))
    }
}
