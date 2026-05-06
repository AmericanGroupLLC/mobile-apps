package com.americangroupllc.pocket.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Alarm fired: ${intent.action}")
        // TODO wake the user with a high-priority foreground notification + sound.
    }
}
