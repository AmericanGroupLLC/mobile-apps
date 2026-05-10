package com.americangroupllc.buddyplay.core.models

import kotlinx.serialization.Serializable

/**
 * The transport an active game session is using. Surfaced in the lobby so
 * the user knows whether they're on Wi-Fi, Hotspot, or BLE.
 */
@Serializable
enum class Transport {
    WIFI, HOTSPOT, BLE;

    val displayName: String
        get() = when (this) {
            WIFI    -> "Local Wi-Fi"
            HOTSPOT -> "Mobile Hotspot"
            BLE     -> "Bluetooth"
        }

    val supportsRealtime: Boolean
        get() = this != BLE
}
