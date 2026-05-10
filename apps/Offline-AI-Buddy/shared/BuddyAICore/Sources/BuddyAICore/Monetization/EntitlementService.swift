import Foundation

/// Slot for the subscription / lifetime IAP entitlement. v1 ships a
/// RevenueCat-backed impl AND a `NoopEntitlementService` that always
/// returns the free tier (used in dev builds without the RevenueCat
/// API key set).
public protocol EntitlementService: Sendable {
    func currentEntitlement() async -> EntitlementState
    /// Open the platform paywall + complete purchase. Updates entitlement
    /// state on success. Throws on user cancel.
    func purchaseSubscription(productId: String) async throws
    func purchaseLifetime(productId: String) async throws
    func restorePurchases() async throws
}

public final class NoopEntitlementService: EntitlementService {
    public init() {}

    public func currentEntitlement() async -> EntitlementState { .free }

    public func purchaseSubscription(productId: String) async throws {
        // No-op in dev builds.
    }

    public func purchaseLifetime(productId: String) async throws {
        // No-op in dev builds.
    }

    public func restorePurchases() async throws {
        // No-op in dev builds.
    }
}

#if canImport(RevenueCat)
// import RevenueCat
// public final class RevenueCatEntitlementService: EntitlementService { ... }
// — wired in iOS app target (not in shared package) so the SPM dep
//   stays out of the test target.
#endif
