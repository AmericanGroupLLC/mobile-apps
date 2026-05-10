package com.americangroupllc.card.reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.americangroupllc.card.core.domain.ReminderScheduler
import com.americangroupllc.card.core.models.Card
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReminderService @Inject constructor(
    @ApplicationContext private val ctx: Context,
) {
    private val alarmManager: AlarmManager =
        ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun schedule(card: Card) {
        val at = card.reminderAtEpochMs ?: return
        val nextFire = ReminderScheduler.nextFireTime(at) ?: return

        val intent = Intent(ctx, ReminderReceiver::class.java).apply {
            putExtra(EXTRA_CARD_ID, card.id)
            putExtra(EXTRA_CARD_TEXT, card.text)
        }
        val pi = PendingIntent.getBroadcast(
            ctx, card.id.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        // setAlarmClock signals the user actively wants this fire-time and survives Doze.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
            && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, nextFire, pi)
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextFire, pi)
        }
    }

    fun cancel(cardId: String) {
        val intent = Intent(ctx, ReminderReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            ctx, cardId.hashCode(), intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        ) ?: return
        alarmManager.cancel(pi)
        pi.cancel()
    }

    companion object {
        const val EXTRA_CARD_ID = "card_id"
        const val EXTRA_CARD_TEXT = "card_text"
    }
}
