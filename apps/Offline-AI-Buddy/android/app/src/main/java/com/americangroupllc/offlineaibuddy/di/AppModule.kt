package com.americangroupllc.offlineaibuddy.di

import android.content.Context
import com.americangroupllc.offlineaibuddy.BuildConfig
import com.americangroupllc.offlineaibuddy.core.models.ModelManifest
import com.americangroupllc.offlineaibuddy.core.monetization.AdGate
import com.americangroupllc.offlineaibuddy.core.monetization.EntitlementService
import com.americangroupllc.offlineaibuddy.core.monetization.NoopAdGate
import com.americangroupllc.offlineaibuddy.core.monetization.NoopEntitlementService
import com.americangroupllc.offlineaibuddy.core.observability.AnalyticsService
import com.americangroupllc.offlineaibuddy.core.observability.CrashReportingService
import com.americangroupllc.offlineaibuddy.core.observability.NoopAnalyticsService
import com.americangroupllc.offlineaibuddy.core.observability.NoopCrashReportingService
import com.americangroupllc.offlineaibuddy.core.storage.ChatHistoryStore
import com.americangroupllc.offlineaibuddy.core.storage.ModelStore
import com.americangroupllc.offlineaibuddy.core.storage.ProfilesStore
import com.americangroupllc.offlineaibuddy.core.storage.QuotaStore
import com.americangroupllc.offlineaibuddy.llm.LlamaService
import com.americangroupllc.offlineaibuddy.monetization.AdMobAdGate
import com.americangroupllc.offlineaibuddy.monetization.RevenueCatEntitlementService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt providers. Same DSL-friendly shape as BuddyPlay's `AppModule`.
 *
 * EntitlementService + AdGate fall back to Noop impls when their build
 * config keys are empty (dev builds + forks without RevenueCat / AdMob
 * accounts).
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun provideModelManifest(): ModelManifest = ModelManifest.defaultV1

    @Provides @Singleton
    fun provideProfilesStore(@ApplicationContext ctx: Context): ProfilesStore =
        ProfilesStore(ctx.filesDir.resolve("offlineaibuddy"))

    @Provides @Singleton
    fun provideChatHistoryStore(@ApplicationContext ctx: Context): ChatHistoryStore =
        ChatHistoryStore(ctx.filesDir.resolve("offlineaibuddy"))

    @Provides @Singleton
    fun provideQuotaStore(@ApplicationContext ctx: Context): QuotaStore =
        QuotaStore(ctx.filesDir.resolve("offlineaibuddy"))

    @Provides @Singleton
    fun provideModelStore(@ApplicationContext ctx: Context): ModelStore =
        ModelStore(ctx.filesDir.resolve("offlineaibuddy"))

    @Provides @Singleton
    fun provideLlamaService(store: ModelStore, manifest: ModelManifest): LlamaService =
        LlamaService(store, manifest)

    @Provides @Singleton
    fun provideEntitlementService(@ApplicationContext ctx: Context): EntitlementService =
        if (BuildConfig.REVENUECAT_API_KEY.isNotEmpty()) {
            RevenueCatEntitlementService(ctx, BuildConfig.REVENUECAT_API_KEY)
        } else {
            NoopEntitlementService()
        }

    @Provides @Singleton
    fun provideAdGate(@ApplicationContext ctx: Context): AdGate =
        if (BuildConfig.ADMOB_APP_ID.isNotEmpty()) {
            AdMobAdGate(ctx)
        } else {
            NoopAdGate()
        }

    @Provides @Singleton
    fun provideAnalytics(): AnalyticsService = NoopAnalyticsService()

    @Provides @Singleton
    fun provideCrashReporting(): CrashReportingService = NoopCrashReportingService()
}
