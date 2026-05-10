package com.americangroupllc.buddyplay.di

import android.content.Context
import com.americangroupllc.buddyplay.core.connectivity.ConnectivityBridge
import com.americangroupllc.buddyplay.core.observability.AnalyticsService
import com.americangroupllc.buddyplay.core.observability.CrashReportingService
import com.americangroupllc.buddyplay.core.observability.NoopAnalyticsService
import com.americangroupllc.buddyplay.core.observability.NoopCrashReportingService
import com.americangroupllc.buddyplay.core.storage.DeviceIdProvider
import com.americangroupllc.buddyplay.core.storage.LocalRivalryStore
import com.americangroupllc.buddyplay.connectivity.AndroidDeviceIdProvider
import com.americangroupllc.buddyplay.connectivity.BleTransport
import com.americangroupllc.buddyplay.connectivity.WifiTcpTransport
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt providers. Same DSL-friendly shape as Drift's `AppModule`.
 *
 * v1 wires noop transports for both rungs — Phase 8 swaps in the real
 * `WifiTcpTransport` and `BleTransport`.
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun provideDeviceIdProvider(@ApplicationContext ctx: Context): DeviceIdProvider =
        AndroidDeviceIdProvider(ctx)

    @Provides @Singleton
    fun provideRivalryStore(@ApplicationContext ctx: Context): LocalRivalryStore =
        LocalRivalryStore(ctx.filesDir.resolve("buddyplay"))

    @Provides @Singleton
    fun provideAnalytics(): AnalyticsService = NoopAnalyticsService()

    @Provides @Singleton
    fun provideCrashReporting(): CrashReportingService = NoopCrashReportingService()

    @Provides @Singleton
    fun provideConnectivityBridge(@ApplicationContext ctx: Context): ConnectivityBridge =
        ConnectivityBridge(wifi = WifiTcpTransport(ctx), ble = BleTransport(ctx))
}
