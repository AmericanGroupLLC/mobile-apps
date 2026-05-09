package com.myhealth.wear.complication

import android.app.PendingIntent
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.RangedValueComplicationData
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import com.myhealth.wear.MainActivity

/** Surfaces the readiness score (0-100) on any watch face that supports
 *  SHORT_TEXT or RANGED_VALUE complications. */
class ReadinessComplicationService : ComplicationDataSourceService() {

    override fun getPreviewData(type: ComplicationType): ComplicationData? = when (type) {
        ComplicationType.RANGED_VALUE -> rangedValue(78)
        ComplicationType.SHORT_TEXT -> shortText(78)
        else -> null
    }

    override fun onComplicationRequest(req: ComplicationRequest, listener: ComplicationRequestListener) {
        val score = readReadinessScore()
        val data = when (req.complicationType) {
            ComplicationType.RANGED_VALUE -> rangedValue(score)
            ComplicationType.SHORT_TEXT   -> shortText(score)
            else -> null
        }
        listener.onComplicationData(data)
    }

    private fun readReadinessScore(): Int =
        getSharedPreferences("myhealth_wear", MODE_PRIVATE).getInt("readiness", 70)

    private fun shortText(score: Int) = ShortTextComplicationData.Builder(
        text = PlainComplicationText.Builder("$score").build(),
        contentDescription = PlainComplicationText.Builder("Readiness $score").build(),
    ).setTapAction(openAppPi()).build()

    private fun rangedValue(score: Int) = RangedValueComplicationData.Builder(
        value = score.toFloat(),
        min = 0f,
        max = 100f,
        contentDescription = PlainComplicationText.Builder("Readiness $score").build(),
    ).setText(PlainComplicationText.Builder("$score").build())
     .setTapAction(openAppPi())
     .build()

    private fun openAppPi(): PendingIntent =
        PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
}
