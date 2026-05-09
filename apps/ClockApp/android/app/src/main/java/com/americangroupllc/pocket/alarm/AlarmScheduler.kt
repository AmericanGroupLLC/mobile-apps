package com.americangroupllc.pocket.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

/**
 * Single source of truth for translating a [StoredAlarm] into an
 * AlarmManager pending intent. Used both by the Compose UI when the
 * user toggles an alarm on, and by [BootReceiver] after a reboot.
 */
object AlarmScheduler {

    const val ACTION_ALARM_FIRE = "com.americangroupllc.pocket.ALARM_FIRE"
    const val EXTRA_ID = "alarm_id"
    const val EXTRA_LABEL = "alarm_label"

    fun schedule(context: Context, alarm: StoredAlarm) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = pendingIntent(context, alarm)
        val triggerAt = nextTrigger(alarm.hour, alarm.minute)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (am.canScheduleExactAlarms()) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        } else {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
    }

    fun cancel(context: Context, alarm: StoredAlarm) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(context, alarm))
    }

    private fun pendingIntent(context: Context, alarm: StoredAlarm): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_ALARM_FIRE
            putExtra(EXTRA_ID, alarm.id)
            putExtra(EXTRA_LABEL, alarm.label)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, alarm.id.hashCode(), intent, flags)
    }

    private fun nextTrigger(hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        return cal.timeInMillis
    }
}
