package com.americangroupllc.offlineaibuddy.core.observability

/**
 * Telemetry slot. v1 attaches NoopAnalyticsService; v1.1 will optionally
 * attach a real PostHog/Mixpanel transport behind a Settings opt-in.
 *
 * IMPORTANT: Offline AI Buddy v1 does NOT send any telemetry. This
 * file declares the interface only — no SDK is imported.
 */
interface AnalyticsService {
    fun track(event: String, properties: Map<String, String>)
    fun screen(name: String)
    fun setUserProperty(key: String, value: String)
}

class NoopAnalyticsService : AnalyticsService {
    override fun track(event: String, properties: Map<String, String>) = Unit
    override fun screen(name: String) = Unit
    override fun setUserProperty(key: String, value: String) = Unit
}

interface CrashReportingService {
    fun capture(error: Throwable, context: Map<String, String>)
    fun breadcrumb(message: String, category: String)
}

class NoopCrashReportingService : CrashReportingService {
    override fun capture(error: Throwable, context: Map<String, String>) = Unit
    override fun breadcrumb(message: String, category: String) = Unit
}
