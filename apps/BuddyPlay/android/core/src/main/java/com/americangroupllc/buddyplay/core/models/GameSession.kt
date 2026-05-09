package com.americangroupllc.buddyplay.core.models

import kotlinx.serialization.Serializable

/**
 * One ongoing game between two peers. Decided once via `HostElection` and
 * then immutable for the duration of the match.
 */
@Serializable
data class GameSession(
    val id: String,            // UUID string
    val kind: GameKind,
    val host: Peer,
    val guest: Peer,
    val transport: Transport,
    val startedAt: Long,
) {
    fun isLocalHost(localPeerId: String): Boolean = host.id == localPeerId

    fun opponent(localPeerId: String): Peer =
        if (host.id == localPeerId) guest else host
}
