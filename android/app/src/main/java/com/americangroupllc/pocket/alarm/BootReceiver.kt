package com.americangroupllc.pocket.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Boot complete — rescheduling alarms.")
            // TODO load Alarm rows from Room and re-schedule via AlarmService.
        }
    }
}
