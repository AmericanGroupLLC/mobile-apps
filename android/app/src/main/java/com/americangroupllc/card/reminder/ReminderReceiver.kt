package com.americangroupllc.card.reminder

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.americangroupllc.card.MainActivity
import com.americangroupllc.card.R
import com.americangroupllc.card.core.obs.AnalyticsEvent
import com.americangroupllc.card.core.obs.AnalyticsService
import com.americangroupllc.card.core.obs.Surface

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val text = intent.getStringExtra(ReminderService.EXTRA_CARD_TEXT) ?: return
        val cardId = intent.getStringExtra(ReminderService.EXTRA_CARD_ID) ?: return

        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Reminders", NotificationManager.IMPORTANCE_HIGH)
            )
        }

        val openApp = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val n = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(ctx.getString(R.string.app_name))
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(openApp)
            .setAutoCancel(true)
            .build()

        nm.notify(cardId.hashCode(), n)
        AnalyticsService.shared.track(AnalyticsEvent.ReminderFired(Surface.APP))
    }

    companion object {
        const val CHANNEL_ID = "card_reminders"
    }
}
