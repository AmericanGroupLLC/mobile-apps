package com.myhealth.app.notifications

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.myhealth.app.MainActivity
import com.myhealth.app.R
import com.myhealth.app.data.room.MedicineDao
import com.myhealth.app.data.room.MedicineEntity
import com.myhealth.core.models.MedicineSchedule
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.util.Calendar

/**
 * Schedules per-dose local notifications via AlarmManager. Mirrors the iOS
 * MedicineReminderService (Take / Snooze 10 min). Reschedules every active
 * medicine on app start and on device reboot.
 */
@Singleton
class MedicineReminderScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
    private val medicineDao: MedicineDao,
) {
    companion object {
        const val CHANNEL_ID = "medicine_reminders"
        const val ACTION_TAKE = "com.myhealth.action.MED_TAKE"
        const val ACTION_SNOOZE = "com.myhealth.action.MED_SNOOZE"
        const val EXTRA_MEDICINE_ID = "medicine_id"
        const val EXTRA_MEDICINE_NAME = "medicine_name"
        const val EXTRA_MEDICINE_DOSAGE = "medicine_dosage"
    }

    private val alarmMgr by lazy { context.getSystemService(Context.ALARM_SERVICE) as AlarmManager }
    private val nm by lazy { context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager }

    init { ensureChannel() }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(
                CHANNEL_ID, "Medicine reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Time-of-day medicine alarms." }
            nm.createNotificationChannel(chan)
        }
    }

    fun reschedule(medicine: MedicineEntity) {
        val schedule = Json.decodeFromString<MedicineSchedule>(medicine.scheduleJSON)
        cancel(medicine.id)
        for (time in schedule.times) {
            for (weekday in schedule.weekdays) {
                val triggerAt = nextTriggerMillis(weekday, time.hour, time.minute)
                val intent = Intent(context, MedicineAlarmReceiver::class.java).apply {
                    putExtra(EXTRA_MEDICINE_ID, medicine.id)
                    putExtra(EXTRA_MEDICINE_NAME, medicine.name)
                    putExtra(EXTRA_MEDICINE_DOSAGE, medicine.dosage)
                }
                val pi = PendingIntent.getBroadcast(
                    context, requestCode(medicine.id, weekday, time.hour, time.minute),
                    intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmMgr.setRepeating(
                    AlarmManager.RTC_WAKEUP, triggerAt,
                    AlarmManager.INTERVAL_DAY * 7, pi
                )
            }
        }
    }

    fun cancel(medicineId: String) {
        // Best-effort cancel across the full request-code space we use.
        for (weekday in 1..7) for (h in 0..23) for (m in 0..59 step 5) {
            val intent = Intent(context, MedicineAlarmReceiver::class.java)
            val pi = PendingIntent.getBroadcast(
                context, requestCode(medicineId, weekday, h, m),
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            ) ?: continue
            alarmMgr.cancel(pi)
            pi.cancel()
        }
    }

    fun resyncAll() {
        CoroutineScope(Dispatchers.IO).launch {
            medicineDao.observeActive().collect { meds ->
                meds.forEach { reschedule(it) }
            }
        }
    }

    fun postNotification(medicineId: String, name: String, dosage: String) {
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_MEDICINE_ID, medicineId)
        }
        val openPi = PendingIntent.getActivity(
            context, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val takePi = actionPendingIntent(ACTION_TAKE, medicineId, name, dosage, requestSeed = 1)
        val snoozePi = actionPendingIntent(ACTION_SNOOZE, medicineId, name, dosage, requestSeed = 2)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Time for $name")
            .setContentText(if (dosage.isBlank()) "Tap to mark as taken." else "$dosage — tap to mark as taken.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(openPi)
            .addAction(android.R.drawable.ic_menu_save, "Take", takePi)
            .addAction(android.R.drawable.ic_menu_recent_history, "Snooze 10 min", snoozePi)
            .build()
        nm.notify(medicineId.hashCode(), notification)
    }

    private fun actionPendingIntent(
        action: String, medicineId: String, name: String, dosage: String, requestSeed: Int
    ): PendingIntent {
        val intent = Intent(context, MedicineAlarmReceiver::class.java).apply {
            this.action = action
            putExtra(EXTRA_MEDICINE_ID, medicineId)
            putExtra(EXTRA_MEDICINE_NAME, name)
            putExtra(EXTRA_MEDICINE_DOSAGE, dosage)
        }
        return PendingIntent.getBroadcast(
            context, medicineId.hashCode() * 100 + requestSeed, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun requestCode(medicineId: String, weekday: Int, hour: Int, minute: Int): Int =
        ((medicineId.hashCode() and 0xFFFF) shl 16) or
                ((weekday and 0x7) shl 13) or ((hour and 0x1F) shl 8) or (minute and 0xFF)

    private fun nextTriggerMillis(weekday: Int, hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply {
            set(Calendar.DAY_OF_WEEK, weekday)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (target.before(now)) target.add(Calendar.WEEK_OF_YEAR, 1)
        return target.timeInMillis
    }
}
