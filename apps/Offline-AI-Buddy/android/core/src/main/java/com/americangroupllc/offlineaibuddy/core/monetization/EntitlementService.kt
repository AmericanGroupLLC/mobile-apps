package com.americangroupllc.offlineaibuddy.core.monetization

import com.americangroupllc.offlineaibuddy.core.models.EntitlementState

/**
 * Subscription/lifetime IAP entitlement gate. Mirrors
 * `BuddyAICore.EntitlementService`.
 */
interface EntitlementService {
    suspend fun currentEntitlement(): EntitlementState
    suspend fun purchaseSubscription(productId: String)
    suspend fun purchaseLifetime(productId: String)
    suspend fun restorePurchases()
}

class NoopEntitlementService : EntitlementService {
    override suspend fun currentEntitlement(): EntitlementState = EntitlementState.FREE
    override suspend fun purchaseSubscription(productId: String) = Unit
    override suspend fun purchaseLifetime(productId: String) = Unit
    override suspend fun restorePurchases() = Unit
}

interface AdGate {
    suspend fun isReady(): Boolean
    /** Present a cached interstitial. Returns true if the user finished it. */
    suspend fun watchAd(): Boolean
}

class NoopAdGate : AdGate {
    override suspend fun isReady(): Boolean = false
    override suspend fun watchAd(): Boolean = true   // Dev-build pretend
}
