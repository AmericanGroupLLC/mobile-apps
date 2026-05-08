package com.americangroupllc.buddyplay.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.buddyplay.core.models.GameKind
import com.americangroupllc.buddyplay.core.models.Peer
import com.americangroupllc.buddyplay.core.models.Transport
import com.americangroupllc.buddyplay.games.chess.ChessScreen
import com.americangroupllc.buddyplay.games.ludo.LudoScreen
import com.americangroupllc.buddyplay.games.racer.RacerScreen

/**
 * Routes a [GameKind] to the corresponding game screen composable, with a small
 * "Back to Home" affordance so the navigation graph is exercisable end-to-end
 * even when there is no real connected peer yet (the real Phase-8 multiplayer
 * pump will provide actual remote [Peer]s + the negotiated [Transport]).
 *
 * The Peer values constructed here are local-only placeholders so the existing
 * game UIs (which already accept Peer arguments) render against a sane state.
 */
@Composable
fun GameRouteHost(kind: GameKind, onBack: () -> Unit) {
    val host  = placeholderPeer(id = "local-host",  name = "You")
    val guest = placeholderPeer(id = "local-guest", name = "Friend")

    Column(
        Modifier.fillMaxSize().padding(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        when (kind) {
            GameKind.CHESS -> ChessScreen(host = host, guest = guest)
            GameKind.LUDO  -> LudoScreen(host = host, guest = guest)
            GameKind.RACER -> RacerScreen(
                host = host,
                guest = guest,
                localPlayerId = host.id,
                transport = Transport.WIFI,
            )
        }
        OutlinedButton(
            onClick = onBack,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
        ) { Text("Back to Home") }
    }
}

private fun placeholderPeer(id: String, name: String) = Peer(
    id = id,
    displayName = name,
    platform = Peer.Platform.ANDROID,
    lastSeenAt = 0L,
)
