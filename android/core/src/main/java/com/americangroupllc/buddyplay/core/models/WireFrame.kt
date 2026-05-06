package com.americangroupllc.buddyplay.core.models

import kotlinx.serialization.Serializable

/**
 * The on-the-wire envelope for every BuddyPlay frame. The [v] field is
 * the ONLY breaking-change escape hatch: a decoder receiving an unknown
 * major version returns [WireCodec.Error.UnsupportedVersion] and the UI
 * surfaces an "Update your friend's app" toast.
 */
@Serializable
data class WireFrame(
    val v: Int = CURRENT_VERSION,
    val sessionId: String,
    val from: String,
    val kind: Kind,
    val ts: Long,
    /** Base64-encoded payload bytes — kept opaque at the envelope level. */
    val payload: String,
) {
    @Serializable
    enum class Kind { INPUT, STATE, LOBBY, PING, PONG }

    companion object {
        const val CURRENT_VERSION: Int = 1
    }
}
