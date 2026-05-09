package com.americangroupllc.buddyplay.core.storage

import com.americangroupllc.buddyplay.core.models.GameKind
import com.americangroupllc.buddyplay.core.models.Rivalry
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import java.io.File

/**
 * JSON-on-disk store for cumulative head-to-head records. Single file,
 * single process — no need for App Groups or atomic file replace.
 *
 * JVM-friendly so it can be unit-tested without an Android runtime.
 * `:app` provides the actual `directory` (the app's filesDir).
 */
class LocalRivalryStore(private val directory: File) {

    private val file: File = File(directory, "rivalries.json")
    private val json: Json = Json { encodeDefaults = true; ignoreUnknownKeys = true }
    private val lock = Any()

    init { directory.mkdirs() }

    fun loadAll(): List<Rivalry> = synchronized(lock) {
        if (!file.exists()) return emptyList()
        return try {
            json.decodeFromString(ListSerializer(serializer<Rivalry>()), file.readText())
        } catch (_: Throwable) {
            // Corrupt JSON falls back to empty so a single bad write can
            // never brick the screen.
            emptyList()
        }
    }

    fun load(opponentId: String): Rivalry? = loadAll().firstOrNull { it.opponentId == opponentId }

    fun record(
        opponentId: String,
        opponentName: String,
        kind: GameKind,
        outcome: Rivalry.Outcome,
        atMillis: Long = System.currentTimeMillis(),
    ) = synchronized(lock) {
        val all = loadAll().toMutableList()
        val idx = all.indexOfFirst { it.opponentId == opponentId }
        if (idx >= 0) {
            val r = all[idx]
            r.opponentName = opponentName
            r.record(outcome, kind, atMillis)
        } else {
            val r = Rivalry(opponentId = opponentId, opponentName = opponentName, lastPlayedAt = atMillis)
            r.record(outcome, kind, atMillis)
            all += r
        }
        save(all)
    }

    fun eraseAll() = synchronized(lock) {
        file.delete()
    }

    private fun save(list: List<Rivalry>) {
        file.writeText(json.encodeToString(ListSerializer(serializer<Rivalry>()), list))
    }
}
