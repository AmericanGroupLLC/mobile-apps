package com.americangroupllc.offlineaibuddy.llm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import com.americangroupllc.offlineaibuddy.R
import com.americangroupllc.offlineaibuddy.core.models.ModelManifest
import com.americangroupllc.offlineaibuddy.core.storage.ModelStore
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import java.io.File
import java.net.URL

/**
 * Foreground-service WorkManager job that downloads the GGUF model.
 * Falls back through every mirror in `ModelManifest.urls`. Verifies
 * SHA-256 if the manifest provides one. Reports progress via a
 * sticky notification ("Downloading Offline AI Buddy model…").
 *
 * Mirrors iOS `ModelDownloader`.
 */
@HiltWorker
class ModelDownloadWorker @AssistedInject constructor(
    @Assisted ctx: Context,
    @Assisted params: WorkerParameters,
    private val manifest: ModelManifest,
    private val store: ModelStore,
) : CoroutineWorker(ctx, params) {

    override suspend fun doWork(): Result {
        setForeground(makeForegroundInfo(0))

        for (url in manifest.urls) {
            try {
                val tmp = downloadOne(url)
                if (manifest.sha256.isNotEmpty()) {
                    val ok = store.verify(tmp.name, manifest.sha256)
                    if (!ok) {
                        tmp.delete(); continue
                    }
                }
                store.install(tmp, "${manifest.name}.gguf")
                return Result.success()
            } catch (_: Throwable) {
                continue
            }
        }
        return Result.retry()
    }

    private suspend fun downloadOne(urlStr: String): File {
        val tmp = File(applicationContext.cacheDir, "model.partial")
        URL(urlStr).openStream().use { input ->
            tmp.outputStream().use { out -> input.copyTo(out) }
        }
        return tmp
    }

    private fun makeForegroundInfo(progress: Int): ForegroundInfo {
        val channelId = "model-download"
        val nm = applicationContext.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(channelId, "Model download", NotificationManager.IMPORTANCE_LOW)
            nm.createNotificationChannel(ch)
        }
        val notif: Notification = NotificationCompat.Builder(applicationContext, channelId)
            .setContentTitle("Downloading Offline AI Buddy model")
            .setContentText("$progress%")
            .setProgress(100, progress, progress == 0)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .build()
        return ForegroundInfo(NOTIFICATION_ID, notif)
    }

    companion object {
        const val NOTIFICATION_ID = 4242
    }
}
