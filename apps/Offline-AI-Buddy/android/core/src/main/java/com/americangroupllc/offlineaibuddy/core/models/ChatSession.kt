package com.americangroupllc.offlineaibuddy.core.models

import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val id: String,
    val role: Role,
    val text: String,
    val tsMillis: Long = System.currentTimeMillis(),
) {
    @Serializable
    enum class Role { USER, ASSISTANT, SYSTEM }
}

@Serializable
data class ChatSession(
    val id: String,
    val profileId: String,
    val language: Language,
    val kind: Kind,
    val messages: List<ChatMessage> = emptyList(),
    val startedAtMillis: Long = System.currentTimeMillis(),
) {
    @Serializable
    enum class Kind(val displayName: String, val availableInKidSafe: Boolean) {
        CHAT("Chat", true),
        ROAST("Roast", false),
        DAILY_CHALLENGE("Daily Challenge", true),
        PARTY_QUESTIONS("Party Questions", true),
        GAME_COACH("Game Coach", true),
        TRANSLATE("Translate", true),
    }
}
