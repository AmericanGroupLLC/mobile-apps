package com.americangroupllc.drift.push

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * Firebase Cloud Messaging receiver - stub. Real implementation extends
 * `com.google.firebase.messaging.FirebaseMessagingService`. We keep the
 * symbol as a placeholder class - now extending [Service] so the lint
 * check `Instantiatable` passes - until the FCM SDK is wired in a
 * follow-up.
 */
class DriftMessagingService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
}
