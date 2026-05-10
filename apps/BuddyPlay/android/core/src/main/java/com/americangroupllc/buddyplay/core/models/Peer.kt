package com.americangroupllc.buddyplay.core.models

import kotlinx.serialization.Serializable

/**
 * A peer is another BuddyPlay device the user can play with. The [id] is
 * generated once on first launch and persisted in `device.json`. It's not
 * a user identity — just a stable handle so the rivalry store can keep
 * tallies across sessions with the same person.
 */
@Serializable
data class Peer(
    val id: String,           // UUID string
    val displayName: String,
    val platform: Platform,
    val lastSeenAt: Long,     // epoch millis
) {
    @Serializable
    enum class Platform { IOS, ANDROID }
}
