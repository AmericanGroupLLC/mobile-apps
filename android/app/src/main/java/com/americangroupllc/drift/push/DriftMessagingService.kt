package com.americangroupllc.drift.push

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.americangroupllc.drift.MainActivity
import com.americangroupllc.drift.R
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicInteger

private val Context.pushDataStore by preferencesDataStore(name = "drift_push")

/**
 * Real Firebase Cloud Messaging receiver. Wires:
 *   - onMessageReceived → posts a notification on the high-importance
 *     `messages` channel; tap opens MainActivity carrying the deeplink.
 *   - onNewToken         → persists the FCM token into DataStore so the
 *     next authenticated network call can sync it to the backend.
 *
 * The `messages` NotificationChannel is also created lazily here so that
 * the very first push after install posts even if the app process was
 * just spawned by the FCM service binding.
 */
class DriftMessagingService : FirebaseMessagingService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val notificationId = AtomicInteger(1000)

    override fun onMessageReceived(message: RemoteMessage) {
        ensureChannel(this)

        // Either the notification block (display message from FCM console)
        // or a data-only payload from our own backend.
        val title    = message.notification?.title ?: message.data["title"] ?: getString(R.string.app_name)
        val body     = message.notification?.body  ?: message.data["body"]  ?: ""
        val deeplink = message.data["deeplink"] // e.g. "drift://chat/<conversationId>"

        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!deeplink.isNullOrBlank()) {
                putExtra(EXTRA_DEEPLINK, deeplink)
                action = Intent.ACTION_VIEW
            }
        }
        val pending = PendingIntent.getActivity(
            this, notificationId.get(), tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_MESSAGES)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(notificationId.incrementAndGet(), notif)
    }

    override fun onNewToken(token: String) {
        Log.i(TAG, "FCM token refreshed (len=${token.length})")
        scope.launch {
            // Persist locally — backend sync happens on next authenticated
            // call (the SupabaseClient pulls this and posts to /tokens).
            applicationContext.pushDataStore.edit { it[FCM_TOKEN_KEY] = token }
        }
        // No Retrofit/Ktor token-registration endpoint exists yet on the
        // backend (see backend/supabase/functions/). When one lands we'll
        // POST `{ token }` to functions/v1/register-push from here.
    }

    companion object {
        private const val TAG = "DriftMessagingService"
        const val CHANNEL_MESSAGES = "messages"
        const val EXTRA_DEEPLINK   = "drift.deeplink"
        val FCM_TOKEN_KEY = stringPreferencesKey("fcm_token")

        /**
         * Idempotent. Safe to call from MainApplication or the service —
         * NotificationManager.createNotificationChannel is a no-op if the
         * channel already exists with the same id.
         */
        fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_MESSAGES) != null) return
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_MESSAGES,
                    "Messages",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "New matches and chat messages"
                    enableLights(true)
                    enableVibration(true)
                }
            )
        }
    }
}
