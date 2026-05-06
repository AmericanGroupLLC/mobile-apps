package com.americangroupllc.card.reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.americangroupllc.card.core.storage.CardRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Re-schedules every incomplete reminder after a reboot or app upgrade.
 * Card relies on AlarmManager which loses pending alarms across reboot, so
 * this is required for the "set a reminder, reboot, it still fires" guarantee.
 */
@AndroidEntryPoint
class BootReceiver : BroadcastReceiver() {
    @Inject lateinit var repo: CardRepository
    @Inject lateinit var reminderService: ReminderService

    override fun onReceive(ctx: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                val pendingResult = goAsync()
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        repo.getAll()
                            .filter { it.reminderAtEpochMs != null && !it.isCompleted }
                            .forEach { reminderService.schedule(it) }
                    } finally {
                        pendingResult.finish()
                    }
                }
            }
        }
    }
}
