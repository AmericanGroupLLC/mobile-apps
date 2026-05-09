package com.myhealth.app

import android.app.Application
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.myhealth.app.notifications.MedicineReminderScheduler
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

/**
 * Hilt entry point. Bootstraps WorkManager and re-syncs medicine reminders
 * the first time the process starts.
 */
@HiltAndroidApp
class MyHealthApp : Application(), Configuration.Provider {

    @Inject lateinit var workerFactory: HiltWorkerFactory
    @Inject lateinit var medicineScheduler: MedicineReminderScheduler

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()

    override fun onCreate() {
        super.onCreate()
        // Crash reporting — opt-in via Settings + DSN must be configured.
        com.myhealth.app.crash.CrashReportingService.bootstrapIfEnabled(
            context = this,
            releaseName = "MyHealth-Android@${BuildConfig.VERSION_NAME ?: "1.0"}"
        )
        // Product analytics — same opt-in pattern, separate API key.
        com.myhealth.app.analytics.AnalyticsService.bootstrapIfEnabled(this)
        // Re-arm reminders for any active medicine on cold start.
        medicineScheduler.resyncAll()
    }
}
