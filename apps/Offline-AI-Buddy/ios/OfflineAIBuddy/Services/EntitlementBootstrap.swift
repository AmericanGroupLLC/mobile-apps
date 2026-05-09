import Foundation
import BuddyAICore

/// App-side wrapper around `EntitlementService`. Dev builds attach
/// `NoopEntitlementService`; release builds attach a RevenueCat impl
/// (lives in Services/RevenueCatEntitlementService.swift, gated by
/// `canImport(RevenueCat)`).
@MainActor
final class EntitlementBootstrap: ObservableObject {

    @Published private(set) var state: EntitlementState = .free

    private let service: EntitlementService

    init() {
        #if canImport(RevenueCat)
        // service = RevenueCatEntitlementService(apiKey: ProcessInfo.processInfo.environment["REVENUECAT_API_KEY_IOS"] ?? "")
        service = NoopEntitlementService()
        #else
        service = NoopEntitlementService()
        #endif
        Task { await refresh() }
    }

    func refresh() async {
        state = await service.currentEntitlement()
    }

    func purchaseSubscription() async throws {
        try await service.purchaseSubscription(productId: "oab_pro_monthly")
        await refresh()
    }

    func purchaseLifetime() async throws {
        try await service.purchaseLifetime(productId: "oab_pro_lifetime")
        await refresh()
    }

    func restorePurchases() async throws {
        try await service.restorePurchases()
        await refresh()
    }
}
