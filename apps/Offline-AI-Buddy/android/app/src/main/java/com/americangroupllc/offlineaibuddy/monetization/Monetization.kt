package com.americangroupllc.offlineaibuddy.monetization

import android.app.Activity
import android.content.Context
import com.americangroupllc.offlineaibuddy.core.models.EntitlementState
import com.americangroupllc.offlineaibuddy.core.monetization.AdGate
import com.americangroupllc.offlineaibuddy.core.monetization.EntitlementService
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * RevenueCat-backed entitlement. Initialised lazily from the API key
 * passed in the constructor (empty key → AppModule wires Noop instead,
 * so this class is only instantiated when there's a real key).
 */
class RevenueCatEntitlementService(
    private val ctx: Context,
    private val apiKey: String,
) : EntitlementService {

    init {
        // Real impl:
        // Purchases.logLevel = LogLevel.WARN
        // Purchases.configure(PurchasesConfiguration.Builder(ctx, apiKey).build())
    }

    override suspend fun currentEntitlement(): EntitlementState {
        // Real impl: read CustomerInfo.entitlements.active["pro_unlocked"].
        return EntitlementState.FREE
    }

    override suspend fun purchaseSubscription(productId: String) {
        // Real impl: Purchases.sharedInstance.purchase(...) coroutine bridge.
    }

    override suspend fun purchaseLifetime(productId: String) {
        // Real impl: same as subscription with the lifetime product id.
    }

    override suspend fun restorePurchases() {
        // Real impl: Purchases.sharedInstance.restorePurchases().
    }
}

/**
 * AdMob-backed cached interstitial. Same lazy-init pattern.
 */
class AdMobAdGate(private val ctx: Context) : AdGate {
    init {
        // MobileAds.initialize(ctx) {}  // real impl
    }

    override suspend fun isReady(): Boolean = false   // wire real cache check
    override suspend fun watchAd(): Boolean = true    // resolves true on real ad finish
}
