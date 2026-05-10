package com.americangroupllc.buddyplay.core.models

import kotlinx.serialization.Serializable

/**
 * The catalogue of games BuddyPlay knows about. Adding game #4 (e.g.
 * Tic-Tac-Toe) is one new case here + one new feature module.
 */
@Serializable
enum class GameKind {
    CHESS, LUDO, RACER;

    val displayName: String
        get() = when (this) {
            CHESS -> "Royal Chess"
            LUDO  -> "Dice Kingdom"
            RACER -> "Mini Racer"
        }

    /** Whether the game can run over BLE. Mini Racer needs Wi-Fi or Hotspot. */
    val supportsBle: Boolean
        get() = this != RACER

    val playerCount: Int
        get() = 2
}
