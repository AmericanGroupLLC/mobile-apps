package com.americangroupllc.card.core.obs

import com.americangroupllc.card.core.models.CardKind

/** The capture surface that triggered an event. Mirrors Swift's `Surface` enum. */
enum class Surface(val raw: String) {
    APP("app"),
    SHARE_EXTENSION("share_extension"),
    WATCH("watch"),
    COMPLICATION("complication"),
    TILE("tile"),
}

sealed class AnalyticsEvent(val name: String, val properties: Map<String, String>) {
    class CardCaptured(surface: Surface, kind: CardKind) :
        AnalyticsEvent("card_captured", mapOf("surface" to surface.raw, "kind" to kind.name.lowercase()))

    class CardConverted(from: CardKind, to: CardKind) :
        AnalyticsEvent("card_converted", mapOf("from_kind" to from.name.lowercase(), "to_kind" to to.name.lowercase()))

    class ReminderScheduled(surface: Surface, delayMinutes: Int) :
        AnalyticsEvent("reminder_scheduled", mapOf("surface" to surface.raw, "delay_minutes" to delayMinutes.toString()))

    class ReminderFired(surface: Surface) :
        AnalyticsEvent("reminder_fired", mapOf("surface" to surface.raw))

    class CardDeleted(kind: CardKind) :
        AnalyticsEvent("card_deleted", mapOf("kind" to kind.name.lowercase()))

    class SettingsToggled(propName: String, enabled: Boolean) :
        AnalyticsEvent("settings_toggled", mapOf("name" to propName, "enabled" to enabled.toString()))

    object OnboardingCompleted : AnalyticsEvent("onboarding_completed", emptyMap())
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
