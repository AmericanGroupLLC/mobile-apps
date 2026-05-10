package com.americangroupllc.driftwear.complication

import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.ComplicationRequest

/**
 * Glanceable layer + unread complication. Quick-reply lives in the Tile
 * (`MatchTileService`); this complication just surfaces the count.
 */
class QuickReplyComplicationService : ComplicationDataSourceService() {

    override fun getPreviewData(type: ComplicationType): ComplicationData? = when (type) {
        ComplicationType.SHORT_TEXT -> short("3")
        else -> null
    }

    override fun onComplicationRequest(request: ComplicationRequest, listener: ComplicationRequestListener) {
        if (request.complicationType == ComplicationType.SHORT_TEXT) {
            // Real implementation reads `wave_aggregates.pending_total` for
            // the current user from the local Room cache.
            listener.onComplicationData(short("0"))
        } else {
            listener.onComplicationData(null)
        }
    }

    private fun short(text: String): ComplicationData {
        val plain = PlainComplicationText.Builder(text).build()
        return ShortTextComplicationData.Builder(
            text = plain,
            contentDescription = PlainComplicationText.Builder("Drift unread matches").build(),
        ).build()
    }
}
