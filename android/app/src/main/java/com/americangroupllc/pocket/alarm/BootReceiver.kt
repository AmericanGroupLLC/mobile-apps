package com.americangroupllc.pocket.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Re-schedules every enabled alarm after the device reboots so users
 * don't silently lose alarms across restarts.
 *
 * Reads from [AlarmRepository] and re-issues each via [AlarmScheduler].
 * Uses the [goAsync] pattern so the broadcast can outlive the synchronous
 * `onReceive` call while we touch disk on a background dispatcher.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED
        ) {
            return
        }
        Log.d(TAG, "Boot complete ($action) — rescheduling alarms.")

        val pending = goAsync()
        val appContext = context.applicationContext

        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                val repo = AlarmRepository(appContext)
                val alarms = repo.getEnabled()
                Log.d(TAG, "Rescheduling ${alarms.size} alarm(s).")
                for (alarm in alarms) {
                    runCatching { AlarmScheduler.schedule(appContext, alarm) }
                        .onFailure { Log.e(TAG, "Failed to schedule ${alarm.id}", it) }
                }
            } catch (t: Throwable) {
                Log.e(TAG, "Boot reschedule failed", t)
            } finally {
                pending.finish()
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
