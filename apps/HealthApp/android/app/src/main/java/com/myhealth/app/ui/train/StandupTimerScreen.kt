package com.myhealth.app.ui.train

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationCompat
import com.myhealth.app.MainActivity
import com.myhealth.app.ui.theme.CarePlusColor

/**
 * Standup timer (sedentary alert). Reuses the AlarmManager pattern from
 * MedicineReminderScheduler. Posts a local notification on each fire via
 * [StandupAlarmReceiver].
 */
@Composable
fun StandupTimerScreen() {
    val context = LocalContext.current
    var enabled by remember { mutableStateOf(false) }
    var minutes by remember { mutableFloatStateOf(50f) }

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Standup timer", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("Sitting too long ↑ glucose, ↓ HRV.",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)

        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
            Column(Modifier.padding(16.dp)) {
                Text("Every ${minutes.toInt()} min", fontWeight = FontWeight.SemiBold)
                Slider(value = minutes, onValueChange = { minutes = it },
                    valueRange = 15f..120f, steps = 21)
            }
        }

        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
            androidx.compose.foundation.layout.Row(
                Modifier.padding(16.dp).fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Standup reminders", modifier = Modifier.weight(1f))
                Switch(checked = enabled, onCheckedChange = {
                    enabled = it
                    if (it) StandupScheduler.schedule(context, minutes.toInt())
                    else StandupScheduler.cancel(context)
                })
            }
        }

        Text("Reminder posts a local notification. Pause anytime.",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
    }
}

object StandupScheduler {
    private const val REQUEST_CODE = 0xC44E
    private const val CHANNEL_ID = "standup_timer"

    fun schedule(context: Context, minutes: Int) {
        ensureChannel(context)
        val mgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, StandupAlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val intervalMs = (minutes.coerceAtLeast(1)) * 60_000L
        mgr.setRepeating(
            AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + intervalMs,
            intervalMs,
            pi
        )
    }

    fun cancel(context: Context) {
        val mgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, StandupAlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pi != null) {
            mgr.cancel(pi)
            pi.cancel()
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val chan = NotificationChannel(CHANNEL_ID, "Standup timer",
                NotificationManager.IMPORTANCE_DEFAULT)
            chan.description = "Standup / sedentary reminders."
            nm.createNotificationChannel(chan)
        }
    }
}

class StandupAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val open = Intent(context, MainActivity::class.java)
        val pi = PendingIntent.getActivity(
            context, 0, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val n = NotificationCompat.Builder(context, "standup_timer")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Stand up & stretch")
            .setContentText("Quick walk or 10 squats — your back will thank you.")
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(0xC44E, n)
    }
}
