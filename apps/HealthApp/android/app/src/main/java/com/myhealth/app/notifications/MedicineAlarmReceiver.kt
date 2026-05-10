package com.myhealth.app.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.myhealth.app.data.room.DoseLogDao
import com.myhealth.app.data.room.DoseLogEntity
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@AndroidEntryPoint
class MedicineAlarmReceiver : BroadcastReceiver() {

    @Inject lateinit var scheduler: MedicineReminderScheduler
    @Inject lateinit var doseLogDao: DoseLogDao

    override fun onReceive(context: Context, intent: Intent) {
        val medicineId = intent.getStringExtra(MedicineReminderScheduler.EXTRA_MEDICINE_ID) ?: return
        val name = intent.getStringExtra(MedicineReminderScheduler.EXTRA_MEDICINE_NAME) ?: "Medicine"
        val dosage = intent.getStringExtra(MedicineReminderScheduler.EXTRA_MEDICINE_DOSAGE) ?: ""

        when (intent.action) {
            MedicineReminderScheduler.ACTION_TAKE -> {
                CoroutineScope(Dispatchers.IO).launch {
                    doseLogDao.insert(
                        DoseLogEntity(
                            medicineId = medicineId,
                            scheduledFor = System.currentTimeMillis(),
                            takenAt = System.currentTimeMillis()
                        )
                    )
                }
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as android.app.NotificationManager
                nm.cancel(medicineId.hashCode())
            }
            MedicineReminderScheduler.ACTION_SNOOZE -> {
                CoroutineScope(Dispatchers.IO).launch {
                    doseLogDao.insert(
                        DoseLogEntity(
                            medicineId = medicineId,
                            scheduledFor = System.currentTimeMillis(),
                            snoozedAt = System.currentTimeMillis()
                        )
                    )
                }
                // Re-fire in 10 minutes.
                val alarmMgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val later = SystemClock.elapsedRealtime() + 10 * 60 * 1000L
                val snoozeIntent = Intent(context, MedicineAlarmReceiver::class.java).apply {
                    putExtra(MedicineReminderScheduler.EXTRA_MEDICINE_ID, medicineId)
                    putExtra(MedicineReminderScheduler.EXTRA_MEDICINE_NAME, name)
                    putExtra(MedicineReminderScheduler.EXTRA_MEDICINE_DOSAGE, dosage)
                }
                val pi = PendingIntent.getBroadcast(
                    context, (medicineId.hashCode() xor 0x55AA), snoozeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmMgr.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, later, pi)
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as android.app.NotificationManager
                nm.cancel(medicineId.hashCode())
            }
            else -> {
                // Default fire from a recurring alarm — show the notification.
                scheduler.postNotification(medicineId, name, dosage)
            }
        }
    }
}
