package com.americangroupllc.drift.core.obs

/** Capture surface that triggered an event. Mirrors Swift's `Surface` enum. */
enum class Surface(val raw: String) {
    APP("app"),
    NOTIFICATION_EXTENSION("notification_extension"),
    WATCH("watch"),
    COMPLICATION("complication"),
    TILE("tile"),
}

/** Drift's canonical event taxonomy. Same names fire from Swift + Kotlin. */
sealed class AnalyticsEvent(val name: String, val properties: Map<String, String>) {
    object OnboardingCompleted : AnalyticsEvent("onboarding_completed", emptyMap())

    class WaveSent(layer: String, surface: Surface) :
        AnalyticsEvent("wave_sent", mapOf("layer" to layer, "surface" to surface.raw))

    class WaveMatched(layer: String, timeToMatchSeconds: Long) :
        AnalyticsEvent("wave_matched", mapOf("layer" to layer, "time_to_match_seconds" to timeToMatchSeconds.toString()))

    class ChatScreenOpen(conversationId: String, tone: String) :
        AnalyticsEvent("chat_screen_open", mapOf("conversation_id" to conversationId, "tone" to tone))

    class ReplySuggestionUsed(tone: String, kind: String) :
        AnalyticsEvent("reply_suggestion_used", mapOf("tone" to tone, "kind" to kind))

    class ReplySuggestionDismissed(tone: String) :
        AnalyticsEvent("reply_suggestion_dismissed", mapOf("tone" to tone))

    object VerificationStarted : AnalyticsEvent("verification_started", emptyMap())

    class VerificationSucceeded(similarityPct: Int) :
        AnalyticsEvent("verification_succeeded", mapOf("similarity_pct" to similarityPct.toString()))

    class VerificationFailed(reason: String) :
        AnalyticsEvent("verification_failed", mapOf("reason" to reason))

    class ReportFiled(reason: String) :
        AnalyticsEvent("report_filed", mapOf("reason" to reason))

    object BlockUser : AnalyticsEvent("block_user", emptyMap())

    class SettingsToggled(propName: String, enabled: Boolean) :
        AnalyticsEvent("settings_toggled", mapOf("name" to propName, "enabled" to enabled.toString()))

    class LayerSwitched(from: String, to: String) :
        AnalyticsEvent("layer_switched", mapOf("from_layer" to from, "to_layer" to to))

    class AppOpenedFromPush(pushType: String) :
        AnalyticsEvent("app_opened_from_push", mapOf("push_type" to pushType))
}

interface AnalyticsTransport {
    fun track(name: String, properties: Map<String, String>)
}

class AnalyticsService {
    var optedIn: Boolean = false
    private var transport: AnalyticsTransport? = null

    fun attach(t: AnalyticsTransport?) { transport = t }

    fun track(event: AnalyticsEvent) {
        if (!optedIn) return
        transport?.track(event.name, event.properties)
    }

    companion object { val shared = AnalyticsService() }
}
