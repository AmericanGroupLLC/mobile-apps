import SwiftUI
import BuddyAICore

struct SubscriptionScreen: View {
    @EnvironmentObject private var entitlement: EntitlementBootstrap
    @EnvironmentObject private var quota: QuotaService
    @State private var error: String?
    @State private var working = false

    var body: some View {
        Form {
            Section("Status") {
                if entitlement.state.proUnlocked {
                    Label("Pro unlocked (\(entitlement.state.source.rawValue))", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Free tier — \(quota.lastDecision.chatsRemaining) chats remaining today")
                }
            }
            if !entitlement.state.proUnlocked {
                Section("Subscribe") {
                    Button("Subscribe — $4.99/mo") {
                        Task { await purchase(.sub) }
                    }
                    Button("Lifetime — $19.99 one-time") {
                        Task { await purchase(.lifetime) }
                    }
                }
            }
            Section {
                Button("Restore purchases") {
                    Task {
                        do { try await entitlement.restorePurchases() } catch { self.error = "\(error)" }
                    }
                }
            }
            if let error {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Premium")
        .disabled(working)
    }

    private enum Tier { case sub, lifetime }
    private func purchase(_ t: Tier) async {
        working = true
        defer { working = false }
        do {
            switch t {
            case .sub:      try await entitlement.purchaseSubscription()
            case .lifetime: try await entitlement.purchaseLifetime()
            }
        } catch {
            self.error = "\(error)"
        }
    }
}
