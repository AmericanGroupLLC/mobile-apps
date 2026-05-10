package com.americangroupllc.card

import android.app.Application
import com.americangroupllc.card.core.obs.AnalyticsService
import com.americangroupllc.card.core.obs.CrashReportingService
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class CardApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Sentry + PostHog wiring is documented in SENTRY.md. Without the
        // SDKs, both remain no-op stubs. With BuildConfig empties, no init.
        if (BuildConfig.SENTRY_DSN.isNotBlank()) {
            // CrashReportingService.shared.attach(SentryTransport(BuildConfig.SENTRY_DSN))
        }
        if (BuildConfig.POSTHOG_API_KEY.isNotBlank()) {
            // AnalyticsService.shared.attach(PostHogTransport(...))
        }

        // Opt-in state will be read from DataStore by SettingsViewModel and
        // pushed back to the services. Defaults to off.
        CrashReportingService.shared.optedIn = false
        AnalyticsService.shared.optedIn = false
    }
}
