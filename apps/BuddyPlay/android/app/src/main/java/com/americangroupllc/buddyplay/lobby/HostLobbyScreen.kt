package com.americangroupllc.buddyplay.lobby

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.buddyplay.core.models.GameKind
import kotlin.random.Random

/** Host lobby. Shows the pairing code while broadcasting on Wi-Fi + BLE. */
@Composable
fun HostLobbyScreen(
    kind: GameKind,
    onDone: () -> Unit,
    onStart: () -> Unit = {},
) {
    val code = remember { makePairingCode() }
    Column(
        Modifier.fillMaxSize().padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(0.2f))
        Text("Hosting ${kind.displayName}")
        PairingCodeView(code = code)
        Text("Ask your friend to open BuddyPlay → Join Nearby Game and tap your phone in the list.")
        Spacer(Modifier.weight(1f))
        Button(onClick = onStart) { Text("Start game") }
        OutlinedButton(onClick = onDone) { Text("Cancel") }
    }
}

private fun makePairingCode(): String {
    val alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
    val chars = (1..4).map { alphabet[Random.nextInt(alphabet.length)] }
    return "BUDD-" + String(chars.toCharArray())
}
