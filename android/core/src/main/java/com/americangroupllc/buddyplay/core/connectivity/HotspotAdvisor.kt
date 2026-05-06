package com.americangroupllc.buddyplay.core.connectivity

import com.americangroupllc.buddyplay.core.models.Peer

/**
 * UI-side helper. Neither iOS nor Android exposes a programmatic API to
 * toggle the personal hotspot in user-installable apps. This object returns
 * human-readable instruction strings the lobby surfaces.
 */
object HotspotAdvisor {
    const val TITLE = "Use your phone's hotspot"
    const val SUBTITLE = "BuddyPlay can't toggle this for you (Apple's + Google's rules), but the steps are short."

    fun enableInstructions(platform: Peer.Platform): String = when (platform) {
        Peer.Platform.IOS -> """
            1. Open Settings → Personal Hotspot.
            2. Toggle "Allow Others to Join" on.
            3. Note the network name + password.
            4. Have your friend join that network from their Wi-Fi settings.
            5. Come back to BuddyPlay — discovery will resume automatically.
        """.trimIndent()
        Peer.Platform.ANDROID -> """
            1. Open Settings → Network & internet → Hotspot & tethering.
            2. Tap "Wi-Fi hotspot" → toggle on.
            3. Note the network name + password.
            4. Have your friend join that network from their Wi-Fi settings.
            5. Come back to BuddyPlay — discovery will resume automatically.
        """.trimIndent()
    }
}
