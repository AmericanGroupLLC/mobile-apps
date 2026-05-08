package com.americangroupllc.pocket

import android.app.Application
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

class PocketApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createAlarmChannel()
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(ALARM_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            ALARM_CHANNEL_ID,
            "Alarms",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifications for alarms that fire."
            enableLights(true)
            enableVibration(true)
            setBypassDnd(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(sound, attrs)
        }
        nm.createNotificationChannel(channel)
    }

    companion object {
        const val ALARM_CHANNEL_ID = "alarms"
    }
}
