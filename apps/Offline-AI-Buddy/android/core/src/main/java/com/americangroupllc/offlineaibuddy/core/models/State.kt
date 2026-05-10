package com.americangroupllc.offlineaibuddy.core.models

import kotlinx.serialization.Serializable

@Serializable
data class EntitlementState(
    val proUnlocked: Boolean,
    val source: Source,
    val expiresAtMillis: Long? = null,
) {
    @Serializable
    enum class Source { FREE, SUBSCRIPTION, LIFETIME }

    companion object {
        val FREE = EntitlementState(proUnlocked = false, source = Source.FREE)
    }
}

@Serializable
data class QuotaState(
    val profileId: String,
    val day: String,                 // yyyy-MM-dd
    val chatsUsed: Int = 0,
    val adUnlocks: Int = 0,
) {
    companion object {
        fun dayString(epochMillis: Long, zoneId: java.time.ZoneId = java.time.ZoneId.systemDefault()): String {
            val zdt = java.time.Instant.ofEpochMilli(epochMillis).atZone(zoneId)
            return zdt.toLocalDate().toString()
        }
    }
}
