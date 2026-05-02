package com.myhealth.wear.tiles

import android.content.Context
import androidx.wear.protolayout.ColorBuilders.argb
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

/** Minimal Readiness tile. Real value comes from the paired phone via shared
 *  storage; for now we display a placeholder so the tile registers cleanly. */
class ReadinessTileService : TileService() {

    override fun onTileRequest(req: RequestBuilders.TileRequest):
        ListenableFuture<TileBuilders.Tile> {
        val score = readReadinessScore(this)
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion("1")
            .setTileTimeline(
                TimelineBuilders.Timeline.fromLayoutElement(
                    layout(score, this)
                )
            )
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(req: RequestBuilders.ResourcesRequest):
        ListenableFuture<ResourceBuilders.Resources> =
        Futures.immediateFuture(ResourceBuilders.Resources.Builder().setVersion("1").build())

    private fun layout(score: Int, ctx: Context): LayoutElement {
        return LayoutElementBuilders.Box.Builder()
            .setWidth(LayoutElementBuilders.expand())
            .setHeight(LayoutElementBuilders.expand())
            .addContent(
                Text.Builder(ctx, "Readiness $score")
                    .setTypography(Typography.TYPOGRAPHY_TITLE2)
                    .setColor(argb(0xFFFF7A2A.toInt()))
                    .build()
            )
            .build()
    }

    private fun readReadinessScore(ctx: Context): Int {
        val prefs = ctx.getSharedPreferences("myhealth_wear", Context.MODE_PRIVATE)
        return prefs.getInt("readiness", 70)
    }
}
