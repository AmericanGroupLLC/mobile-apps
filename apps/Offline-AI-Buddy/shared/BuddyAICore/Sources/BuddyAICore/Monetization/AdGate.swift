import Foundation

/// The "watch ad for +5 chats" gate. AdMob impl lives in the iOS app
/// target; v1 ships `NoopAdGate` for dev builds without the AdMob app
/// ID set.
public protocol AdGate: Sendable {
    func isReady() async -> Bool
    /// Present a cached interstitial ad. Returns `true` if the user
    /// finished watching it.
    func watchAd() async -> Bool
}

public final class NoopAdGate: AdGate {
    public init() {}

    public func isReady() async -> Bool { false }

    public func watchAd() async -> Bool {
        // Dev builds: pretend the user finished an ad so QuotaTracker
        // round-trips can be exercised end-to-end.
        true
    }
}

#if canImport(GoogleMobileAds)
// import GoogleMobileAds
// public final class AdMobAdGate: AdGate { ... }
// — wired in iOS app target.
#endif
