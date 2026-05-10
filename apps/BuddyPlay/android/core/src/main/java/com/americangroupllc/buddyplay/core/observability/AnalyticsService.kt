package com.americangroupllc.buddyplay.core.observability

/**
 * Telemetry slot. v1 attaches [NoopAnalyticsService]; v1.1 will optionally
 * attach a real PostHog/Mixpanel transport behind a Settings opt-in.
 *
 * IMPORTANT: BuddyPlay v1 does NOT send any telemetry. This file declares
 * the interface only — no SDK is imported.
 */
interface AnalyticsService {
    fun track(event: String, properties: Map<String, String> = emptyMap())
    fun screen(name: String)
    fun setUserProperty(key: String, value: String)
}

class NoopAnalyticsService : AnalyticsService {
    override fun track(event: String, properties: Map<String, String>) {}
    override fun screen(name: String) {}
    override fun setUserProperty(key: String, value: String) {}
}
