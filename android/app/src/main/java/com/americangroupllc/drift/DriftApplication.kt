package com.americangroupllc.drift

import android.app.Application
import com.americangroupllc.drift.core.obs.AnalyticsService
import com.americangroupllc.drift.core.obs.CrashReportingService
import com.americangroupllc.drift.push.DriftMessagingService
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class DriftApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AnalyticsService.shared.optedIn      = false   // wired from settings on first read
        CrashReportingService.shared.optedIn = false
        // Pre-create the FCM messages channel so the first push after a
        // cold install can post immediately.
        DriftMessagingService.ensureChannel(this)
    }
}
