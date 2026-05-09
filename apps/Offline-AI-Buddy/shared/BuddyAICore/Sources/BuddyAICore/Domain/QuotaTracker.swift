import Foundation

/// Pure `(state, event) -> state` reducer for the per-profile, per-day
/// chat quota. Free tier = 10 chats/day; each watched ad = +5 chats;
/// pro entitlement bypasses everything.
public enum QuotaTracker {

    public static let freeDailyLimit: Int = 10
    public static let chatsPerAd: Int = 5

    public enum Event: Hashable, Sendable {
        case chatStarted
        case adWatched
        /// Force-roll the day forward (used at midnight / app foreground).
        case rollover(toDay: String)
    }

    public struct Decision: Hashable, Sendable {
        public let allowed: Bool
        public let chatsRemaining: Int
        public let canWatchAd: Bool

        public init(allowed: Bool, chatsRemaining: Int, canWatchAd: Bool) {
            self.allowed = allowed
            self.chatsRemaining = chatsRemaining
            self.canWatchAd = canWatchAd
        }
    }

    /// Apply an event. Pro-unlocked profiles bypass quota checks.
    public static func reduce(
        state: QuotaState,
        event: Event,
        proUnlocked: Bool
    ) -> QuotaState {
        switch event {
        case .chatStarted:
            if proUnlocked { return state }
            var s = state
            s.chatsUsed += 1
            return s
        case .adWatched:
            if proUnlocked { return state }
            var s = state
            s.adUnlocks += 1
            return s
        case .rollover(let day):
            return QuotaState(profileId: state.profileId, day: day, chatsUsed: 0, adUnlocks: 0)
        }
    }

    /// Decide whether the next chat is allowed.
    public static func decide(state: QuotaState, proUnlocked: Bool) -> Decision {
        if proUnlocked {
            return Decision(allowed: true, chatsRemaining: Int.max, canWatchAd: false)
        }
        let allowance = freeDailyLimit + state.adUnlocks * chatsPerAd
        let remaining = max(0, allowance - state.chatsUsed)
        return Decision(allowed: remaining > 0, chatsRemaining: remaining, canWatchAd: true)
    }
}
