package com.americangroupllc.driftwear.tile

import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Drift's Wear Tile: shows the current discovery layer + unread match
 * count and a wave-back tap.
 *
 * Note: Wear Tiles & Watchface Complications APIs require Guava
 * `Futures.immediateFuture(...)` — Guava is pinned in :wear/build.gradle.kts.
 */
class MatchTileService : TileService() {

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest):
        ListenableFuture<TileBuilders.Tile> {
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion("1")
            .setTileTimeline(
                TimelineBuilders.Timeline.Builder()
                    .addTimelineEntry(TimelineBuilders.TimelineEntry.Builder().build())
                    .build()
            )
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(requestParams: RequestBuilders.ResourcesRequest):
        ListenableFuture<ResourceBuilders.Resources> {
        val resources = ResourceBuilders.Resources.Builder()
            .setVersion("1")
            .build()
        return Futures.immediateFuture(resources)
    }
}
