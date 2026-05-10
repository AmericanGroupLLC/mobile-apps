package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer

/**
 * Deterministic host election for a 2-peer session. Both peers run this
 * locally on the same `(a, b)` tuple and agree on the host without
 * negotiating.
 *
 * Algorithm:
 *   1. The peer with the lexicographically SMALLER `id` wins.
 *   2. Tie-break (impossible with v4 UUIDs but kept for theoretical
 *      completeness): iOS wins over Android.
 */
object HostElection {

    fun host(a: Peer, b: Peer): Peer {
        val cmp = a.id.compareTo(b.id)
        if (cmp < 0) return a
        if (cmp > 0) return b
        // Same id — tie-break on platform.
        return when {
            a.platform == Peer.Platform.IOS && b.platform == Peer.Platform.ANDROID -> a
            b.platform == Peer.Platform.IOS && a.platform == Peer.Platform.ANDROID -> b
            else -> a
        }
    }

    fun guest(a: Peer, b: Peer): Peer = if (host(a, b).id == a.id) b else a
}
