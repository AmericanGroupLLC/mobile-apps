package com.myhealth.wear.tiles

import android.content.Context
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.degrees
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.LayoutElementBuilders.LayoutElement
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.material.Text
import androidx.wear.protolayout.material.Typography
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Readiness tile.
 *
 * Reads the latest readiness score (0–100) from SharedPreferences (key
 * `readiness` in `myhealth_wear`). The phone-side WearDataLayer push writes
 * to that same prefs file via DataLayer message path `/readiness/latest`,
 * so until that listener lands the prefs fallback is the single source of
 * truth and the tile still renders a real value.
 *
 * Layout: a circular ring around the watch face whose sweep encodes the
 * score, with the score number and the label "Readiness" stacked in the
 * centre. Refresh request fires every 10 minutes via
 * `setFreshnessIntervalMillis`.
 */
class ReadinessTileService : TileService() {

    private companion object {
        const val RESOURCES_VERSION = "1"
        const val PREFS_NAME = "myhealth_wear"
        const val PREFS_KEY = "readiness"
        const val DEFAULT_SCORE = 70
        const val REFRESH_INTERVAL_MILLIS = 10L * 60L * 1000L // 10 minutes
        const val RING_COLOR_FILLED = 0xFFFF7A2A.toInt()      // brand orange
        const val RING_COLOR_TRACK = 0x33FFFFFF                // 20% white
        const val RING_THICKNESS_DP = 6f
    }

    override fun onTileRequest(req: RequestBuilders.TileRequest):
        ListenableFuture<TileBuilders.Tile> {
        val score = readReadinessScore(this).coerceIn(0, 100)
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setFreshnessIntervalMillis(REFRESH_INTERVAL_MILLIS)
            .setTileTimeline(
                TimelineBuilders.Timeline.fromLayoutElement(layout(score, this))
            )
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(req: RequestBuilders.ResourcesRequest):
        ListenableFuture<ResourceBuilders.Resources> =
        Futures.immediateFuture(
            ResourceBuilders.Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build()
        )

    private fun layout(score: Int, ctx: Context): LayoutElement {
        // Sweep angle proportional to score (0..100 → 0..360°).
        val sweep = (score.toFloat() / 100f) * 360f

        // Track ring (full 360° at low opacity).
        val track = LayoutElementBuilders.Arc.Builder()
            .setAnchorAngle(degrees(0f))
            .setAnchorType(LayoutElementBuilders.ARC_ANCHOR_START)
            .addContent(
                LayoutElementBuilders.ArcLine.Builder()
                    .setLength(degrees(360f))
                    .setThickness(dp(RING_THICKNESS_DP))
                    .setColor(argb(RING_COLOR_TRACK))
                    .build()
            )
            .build()

        // Filled portion.
        val ring = LayoutElementBuilders.Arc.Builder()
            .setAnchorAngle(degrees(0f))
            .setAnchorType(LayoutElementBuilders.ARC_ANCHOR_START)
            .addContent(
                LayoutElementBuilders.ArcLine.Builder()
                    .setLength(degrees(sweep))
                    .setThickness(dp(RING_THICKNESS_DP))
                    .setColor(argb(RING_COLOR_FILLED))
                    .build()
            )
            .build()

        // Centre stack: score number + "Readiness" caption.
        val centre = LayoutElementBuilders.Column.Builder()
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .addContent(
                Text.Builder(ctx, score.toString())
                    .setTypography(Typography.TYPOGRAPHY_DISPLAY2)
                    .setColor(argb(RING_COLOR_FILLED))
                    .build()
            )
            .addContent(
                Text.Builder(ctx, "Readiness")
                    .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                    .setColor(argb(0xFFFFFFFF.toInt()))
                    .build()
            )
            .build()

        return LayoutElementBuilders.Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
            .addContent(track)
            .addContent(ring)
            .addContent(centre)
            .build()
    }

    private fun readReadinessScore(ctx: Context): Int {
        val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(PREFS_KEY, DEFAULT_SCORE)
    }
}
