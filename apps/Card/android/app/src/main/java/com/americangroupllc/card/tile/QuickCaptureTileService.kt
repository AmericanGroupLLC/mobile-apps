package com.americangroupllc.card.tile

import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import com.americangroupllc.card.composer.QuickCaptureActivity

/**
 * Quick Settings tile. Tapping it launches the voice-composer activity
 * inside Card. Surface=tile is recorded for analytics.
 */
@RequiresApi(Build.VERSION_CODES.N)
class QuickCaptureTileService : TileService() {

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, QuickCaptureActivity::class.java).apply {
            action = "com.americangroupllc.card.QUICK_CAPTURE"
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        // Use startActivityAndCollapse so the Quick Settings panel closes
        // before the composer opens.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                android.app.PendingIntent.getActivity(
                    this, 0, intent,
                    android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
                )
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
