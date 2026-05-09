package com.americangroupllc.buddyplay.games.chess

import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.buddyplay.core.domain.ChessOutcome
import com.americangroupllc.buddyplay.core.models.Peer

@Composable
fun ChessScreen(host: Peer, guest: Peer) {
    val vm = remember { ChessViewModel(host, guest) }
    Column(
        Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(host.displayName, style = MaterialTheme.typography.bodyMedium)
            Spacer(Modifier.weight(1f))
            outcomeText(vm)?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            if (vm.isInCheck) Text("Check!", color = MaterialTheme.colorScheme.tertiary)
            Spacer(Modifier.weight(1f))
            Text(guest.displayName, style = MaterialTheme.typography.bodyMedium)
        }
        ChessBoardComposable(vm)
    }
}

@Composable
private fun outcomeText(vm: ChessViewModel): String? = when (val o = vm.state.outcome) {
    is ChessOutcome.Checkmate -> {
        val name = if (o.winner == vm.host.id) vm.host.displayName else vm.guest.displayName
        "$name wins by checkmate"
    }
    ChessOutcome.Stalemate           -> "Stalemate · draw"
    ChessOutcome.FiftyMoveRule       -> "50-move rule · draw"
    ChessOutcome.ThreefoldRepetition -> "Threefold repetition · draw"
    is ChessOutcome.Resignation      -> {
        val name = if (o.loser == vm.host.id) vm.host.displayName else vm.guest.displayName
        "$name resigned"
    }
    null -> null
}
