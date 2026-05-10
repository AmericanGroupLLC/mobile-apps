package com.americangroupllc.buddyplay.games.ludo

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.buddyplay.core.domain.LudoOutcome
import com.americangroupllc.buddyplay.core.models.Peer

@Composable
fun LudoScreen(host: Peer, guest: Peer) {
    val vm = remember { LudoViewModel(host, guest) }
    Column(
        Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row {
            val turnId = if (vm.state.outcome == null) vm.state.sideToMove else null
            val turnName = when (turnId) {
                vm.host.id  -> vm.host.displayName
                vm.guest.id -> vm.guest.displayName
                else        -> "—"
            }
            Text("$turnName's turn", style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.weight(1f))
            (vm.state.outcome as? LudoOutcome.Winner)?.let {
                val name = if (it.peerId == vm.host.id) vm.host.displayName else vm.guest.displayName
                Text("$name wins!", color = MaterialTheme.colorScheme.error)
            }
        }
        LudoBoardComposable(vm)
        Button(
            onClick = vm::rollDie,
            enabled = vm.state.outcome == null && vm.lastDieRoll == null,
        ) {
            Text(
                vm.lastDieRoll?.let { "Rolled $it — tap a token to move" }
                    ?: "Roll the die"
            )
        }
    }
}
