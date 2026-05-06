package com.americangroupllc.pocketwear.tile

import android.content.Context
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Minimal next-alarm tile. Real-world version queries the AlarmRepository
 * and renders the next upcoming alarm time. This stub returns an empty tile.
 */
class NextAlarmTileService : TileService() {
    override fun onTileRequest(
        requestParams: androidx.wear.tiles.RequestBuilders.TileRequest
    ): ListenableFuture<TileBuilders.Tile> {
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion("1")
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onResourcesRequest(
        requestParams: androidx.wear.tiles.RequestBuilders.ResourcesRequest
    ): ListenableFuture<androidx.wear.tiles.ResourceBuilders.Resources> {
        return Futures.immediateFuture(
            androidx.wear.tiles.ResourceBuilders.Resources.Builder()
                .setVersion("1")
                .build()
        )
    }
}
