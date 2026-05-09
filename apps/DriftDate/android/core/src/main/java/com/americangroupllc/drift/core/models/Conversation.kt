package com.americangroupllc.drift.core.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Conversation(
    val id: String,
    @SerialName("profile_a_id") val profileAId: String,
    @SerialName("profile_b_id") val profileBId: String,
    val tone: Tone = Tone.SLOW,
    @SerialName("last_read_a")  val lastReadA: String? = null,
    @SerialName("last_read_b")  val lastReadB: String? = null,
    @SerialName("muted_by_a")   val mutedByA: Boolean = false,
    @SerialName("muted_by_b")   val mutedByB: Boolean = false,
    @SerialName("created_at")   val createdAt: String,
) {
    val profileIds: List<String> get() = listOf(profileAId, profileBId)
}

@Serializable
data class Message(
    val id: String,
    @SerialName("conversation_id") val conversationId: String,
    @SerialName("author_id") val authorId: String,
    val text: String,
    @SerialName("created_at") val createdAt: Long,         // epoch millis
)

@Serializable
data class ReplySuggestion(
    val casual: String,
    val context: String,
    val playful: String,
    val tone: Tone,
)
