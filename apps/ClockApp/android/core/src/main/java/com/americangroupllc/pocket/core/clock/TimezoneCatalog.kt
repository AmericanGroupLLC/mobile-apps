package com.americangroupllc.pocket.core.clock

import java.util.TimeZone

data class TimezoneEntry(
    val identifier: String,
    val displayCity: String,
    val region: String
) {
    companion object {
        fun fromIdentifier(id: String): TimezoneEntry {
            val parts = id.split("/")
            val region = parts.firstOrNull() ?: "Other"
            val city = (parts.lastOrNull() ?: id).replace("_", " ")
            return TimezoneEntry(id, city, region)
        }
    }
}

object TimezoneCatalog {
    fun all(): List<TimezoneEntry> =
        TimeZone.getAvailableIDs()
            .filter { "/" in it }
            .map(TimezoneEntry::fromIdentifier)
            .sortedBy { it.identifier }

    fun search(query: String, entries: List<TimezoneEntry> = all()): List<TimezoneEntry> {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return entries
        return entries.filter {
            it.displayCity.lowercase().contains(q) ||
            it.identifier.lowercase().contains(q) ||
            it.region.lowercase().contains(q)
        }
    }
}
