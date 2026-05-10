package com.americangroupllc.pocket.alarm

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.americangroupllc.pocket.MainActivity
import com.americangroupllc.pocket.PocketApplication

/**
 * Fires when an alarm trigger time elapses. Posts a high-priority
 * notification on the "alarms" channel with sound, full-screen intent
 * to launch the app, and a "Dismiss" action.
 */
class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(AlarmScheduler.EXTRA_ID) ?: "unknown"
        val label = intent.getStringExtra(AlarmScheduler.EXTRA_LABEL).orEmpty()
            .ifBlank { "Alarm" }
        val notificationId = id.hashCode()
        Log.d(TAG, "Alarm fired: id=$id label=$label")

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPi = PendingIntent.getActivity(
            context,
            notificationId,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dismissIntent = Intent(context, DismissReceiver::class.java).apply {
            action = ACTION_DISMISS
            putExtra(EXTRA_NOTIF_ID, notificationId)
        }
        val dismissPi = PendingIntent.getBroadcast(
            context,
            notificationId,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val notification = NotificationCompat.Builder(context, PocketApplication.ALARM_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(label)
            .setContentText("Alarm")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(sound)
            .setAutoCancel(true)
            .setFullScreenIntent(openAppPi, true)
            .setContentIntent(openAppPi)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", dismissPi)
            .build()

        nm.notify(notificationId, notification)
    }

    /** Cancels the alarm notification when the user taps "Dismiss". */
    class DismissReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val id = intent.getIntExtra(EXTRA_NOTIF_ID, -1)
            if (id != -1) {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.cancel(id)
            }
        }
    }

    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_DISMISS = "com.americangroupllc.pocket.ALARM_DISMISS"
        const val EXTRA_NOTIF_ID = "notif_id"
    }
}
