package com.americangroupllc.pocket.core.obs

enum class Tool { CLOCK, CALCULATOR, MEASURE, COMPASS, LEVEL }

sealed class AnalyticsEvent(val name: String, val properties: Map<String, String>) {
    class Opened(tool: Tool) : AnalyticsEvent("tool_opened", mapOf("tool" to tool.name.lowercase()))
    class SettingsToggled(propName: String, enabled: Boolean) :
        AnalyticsEvent("settings_toggled", mapOf("name" to propName, "enabled" to enabled.toString()))
    object OnboardingCompleted : AnalyticsEvent("onboarding_completed", emptyMap())
    object AlarmCreated : AnalyticsEvent("alarm_created", emptyMap())
    object AlarmFired : AnalyticsEvent("alarm_fired", emptyMap())
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
