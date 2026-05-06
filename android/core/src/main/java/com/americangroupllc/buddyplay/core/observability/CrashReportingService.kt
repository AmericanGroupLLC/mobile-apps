package com.americangroupllc.buddyplay.core.observability

/**
 * Crash + non-fatal-error reporting slot. v1 attaches
 * [NoopCrashReportingService]; v1.1 will optionally attach Sentry behind a
 * Settings opt-in.
 *
 * IMPORTANT: BuddyPlay v1 does NOT send any crash reports.
 */
interface CrashReportingService {
    fun capture(error: Throwable, context: Map<String, String> = emptyMap())
    fun breadcrumb(message: String, category: String)
}

class NoopCrashReportingService : CrashReportingService {
    override fun capture(error: Throwable, context: Map<String, String>) {}
    override fun breadcrumb(message: String, category: String) {}
}
