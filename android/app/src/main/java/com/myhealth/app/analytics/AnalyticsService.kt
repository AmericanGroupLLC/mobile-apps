package com.myhealth.app.analytics

import android.content.Context
import android.content.SharedPreferences
import com.posthog.PostHog
import com.posthog.android.PostHogAndroid
import com.posthog.android.PostHogAndroidConfig

/**
 * Privacy-first product-analytics wrapper. Mirrors iOS `AnalyticsService`:
 *   * Disabled by default. User must opt in via Settings.
 *   * Reads API key + host from BuildConfig (Sentry-style env-var injection).
 *   * Uses PostHog free tier (1M events/month, EU region by default).
 *   * Mixpanel/Amplitude can be swapped behind this same API.
 */
object AnalyticsService {

    private const val PREFS = "myhealth_analytics"
    private const val KEY_ENABLED = "enabled"
    @Volatile private var started: Boolean = false

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
        if (!enabled && started) {
            PostHog.optOut()
            started = false
        } else if (enabled && !started) {
            bootstrapIfEnabled(context)
        }
    }

    fun bootstrapIfEnabled(context: Context) {
        if (!isEnabled(context) || started) return
        val key = resolveKey() ?: return
        val host = resolveHost()
        val config = PostHogAndroidConfig(apiKey = key, host = host).apply {
            captureApplicationLifecycleEvents = true
            captureScreenViews = false
            sessionReplay = false
            sendFeatureFlagEvent = false
        }
        PostHogAndroid.setup(context, config)
        started = true
    }

    fun track(event: String, properties: Map<String, Any>? = null) {
        if (started) PostHog.capture(event, properties = properties)
    }

    fun screen(name: String, properties: Map<String, Any>? = null) {
        if (started) PostHog.screen(name, properties = properties)
    }

    fun identify(distinctId: String, userProperties: Map<String, Any>? = null) {
        if (started) PostHog.identify(distinctId, userProperties = userProperties)
    }

    fun reset() {
        if (started) PostHog.reset()
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun resolveKey(): String? {
        val fromEnv = System.getenv("POSTHOG_API_KEY")
        if (!fromEnv.isNullOrEmpty()) return fromEnv
        return try {
            val cls = Class.forName("com.myhealth.app.BuildConfig")
            (cls.getField("POSTHOG_API_KEY").get(null) as? String).takeIf { !it.isNullOrEmpty() }
        } catch (_: Throwable) { null }
    }

    private fun resolveHost(): String {
        val fromEnv = System.getenv("POSTHOG_HOST")
        if (!fromEnv.isNullOrEmpty()) return fromEnv
        return try {
            val cls = Class.forName("com.myhealth.app.BuildConfig")
            (cls.getField("POSTHOG_HOST").get(null) as? String).takeUnless { it.isNullOrEmpty() }
                ?: "https://eu.i.posthog.com"
        } catch (_: Throwable) { "https://eu.i.posthog.com" }
    }
}

/** Centralised event names — keep parity with iOS AnalyticsEvent. */
object AnalyticsEvent {
    const val ONBOARDING_STARTED   = "onboarding_started"
    const val ONBOARDING_COMPLETED = "onboarding_completed"
    const val GUEST_MODE_CHOSEN    = "guest_mode_chosen"
    const val SIGN_IN_COMPLETED    = "sign_in_completed"
    const val WORKOUT_STARTED      = "workout_started"
    const val WORKOUT_COMPLETED    = "workout_completed"
    const val MEAL_LOGGED          = "meal_logged"
    const val MEDICINE_ADDED       = "medicine_added"
    const val MEDICINE_DOSE_TAKEN  = "medicine_dose_taken"
    const val BIO_AGE_ESTIMATED    = "bio_age_estimated"
    const val EXPORT_TRIGGERED     = "data_export_triggered"
    const val ERASE_ALL_CONFIRMED  = "data_erase_confirmed"
}
