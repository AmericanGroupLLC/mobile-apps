import Foundation
import BuddyAICore

/// App-side wrapper that surfaces the `QuotaTracker` decision flow as
/// SwiftUI-friendly published state. Reads/writes to `QuotaStore`.
@MainActor
final class QuotaService: ObservableObject {

    @Published private(set) var lastDecision: QuotaTracker.Decision = .init(allowed: true, chatsRemaining: 10, canWatchAd: true)

    private let store: QuotaStore

    init() {
        self.store = try! QuotaStore()
    }

    /// Called before every chat send. Returns whether the next chat is
    /// permitted; updates the published `lastDecision`.
    func mayStartChat(for profileId: UUID, proUnlocked: Bool) -> QuotaTracker.Decision {
        let day = QuotaState.dayString(for: Date())
        let state = store.get(for: profileId, day: day)
        let decision = QuotaTracker.decide(state: state, proUnlocked: proUnlocked)
        lastDecision = decision
        return decision
    }

    func recordChatStarted(for profileId: UUID, proUnlocked: Bool) {
        let day = QuotaState.dayString(for: Date())
        let state = store.get(for: profileId, day: day)
        let next = QuotaTracker.reduce(state: state, event: .chatStarted, proUnlocked: proUnlocked)
        try? store.upsert(next)
    }

    func recordAdWatched(for profileId: UUID, proUnlocked: Bool) {
        let day = QuotaState.dayString(for: Date())
        let state = store.get(for: profileId, day: day)
        let next = QuotaTracker.reduce(state: state, event: .adWatched, proUnlocked: proUnlocked)
        try? store.upsert(next)
    }
}
