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
        // Re-arm reminders for any active medicine on cold start.
        medicineScheduler.resyncAll()
    }
}
