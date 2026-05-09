package com.americangroupllc.offlineaibuddy.core.storage

import com.americangroupllc.offlineaibuddy.core.models.QuotaState
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import java.io.File

/**
 * Per-profile, per-day quota state. Single file holds every profile's
 * entry; rolls over at local midnight. Mirrors `BuddyAICore.QuotaStore`.
 */
class QuotaStore(directory: File) {

    private val file = File(directory, "quota.json").also { directory.mkdirs() }
    private val json = Json { encodeDefaults = true; ignoreUnknownKeys = true }
    private val lock = Any()

    fun load(): List<QuotaState> = synchronized(lock) {
        if (!file.exists()) return emptyList()
        return try {
            json.decodeFromString(ListSerializer(serializer<QuotaState>()), file.readText())
        } catch (_: Throwable) {
            emptyList()
        }
    }

    fun save(states: List<QuotaState>) = synchronized(lock) {
        file.writeText(json.encodeToString(ListSerializer(serializer<QuotaState>()), states))
    }

    fun get(profileId: String, day: String): QuotaState =
        load().firstOrNull { it.profileId == profileId && it.day == day }
            ?: QuotaState(profileId = profileId, day = day)

    fun upsert(state: QuotaState) {
        val all = load().toMutableList()
        val idx = all.indexOfFirst { it.profileId == state.profileId && it.day == state.day }
        if (idx >= 0) all[idx] = state else all += state

        val grouped = all.groupBy { it.profileId }
        val trimmed = grouped.flatMap { (_, days) ->
            days.sortedByDescending { it.day }.take(7)
        }
        save(trimmed)
    }
}
