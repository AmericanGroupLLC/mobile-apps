package com.americangroupllc.offlineaibuddy.core.storage

import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import java.io.File

/**
 * Per-profile JSON file holding chat history. Capped at 200 messages
 * per profile (oldest sessions dropped). Mirrors
 * `BuddyAICore.ChatHistoryStore`.
 */
class ChatHistoryStore(directory: File) {

    private val dir = File(directory, "chats").also { it.mkdirs() }
    private val json = Json { encodeDefaults = true; ignoreUnknownKeys = true }
    private val lock = Any()

    private fun fileFor(profileId: String) = File(dir, "$profileId.json")

    fun load(profileId: String): List<ChatSession> = synchronized(lock) {
        val f = fileFor(profileId)
        if (!f.exists()) return emptyList()
        return try {
            json.decodeFromString(ListSerializer(serializer<ChatSession>()), f.readText())
        } catch (_: Throwable) {
            emptyList()
        }
    }

    fun save(sessions: List<ChatSession>, profileId: String) = synchronized(lock) {
        val trimmed = trim(sessions)
        fileFor(profileId).writeText(json.encodeToString(ListSerializer(serializer<ChatSession>()), trimmed))
    }

    fun eraseAll(profileId: String) = synchronized(lock) {
        fileFor(profileId).delete()
    }

    fun eraseAll() = synchronized(lock) {
        dir.listFiles()?.forEach { it.delete() }
    }

    private fun trim(sessions: List<ChatSession>): List<ChatSession> {
        val total = sessions.sumOf { it.messages.size }
        if (total <= MAX_MESSAGES_PER_PROFILE) return sessions
        val sorted = sessions.sortedBy { it.startedAtMillis }.toMutableList()
        var current = total
        while (current > MAX_MESSAGES_PER_PROFILE && sorted.isNotEmpty()) {
            current -= sorted.removeAt(0).messages.size
        }
        return sorted
    }

    companion object {
        const val MAX_MESSAGES_PER_PROFILE = 200
    }
}
