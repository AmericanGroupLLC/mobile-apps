import Foundation

/// Telemetry slot. v1 attaches `NoopAnalyticsService`; v1.1 will optionally
/// attach a real PostHog/Mixpanel transport behind a Settings opt-in.
///
/// IMPORTANT: BuddyPlay v1 does NOT send any telemetry. This file declares
/// the interface only — no SDK is imported, no transport is wired.
public protocol AnalyticsService {
    func track(_ event: String, properties: [String: String])
    func screen(_ name: String)
    func setUserProperty(_ key: String, value: String)
}

public final class NoopAnalyticsService: AnalyticsService {
    public init() {}
    public func track(_ event: String, properties: [String: String]) {}
    public func screen(_ name: String) {}
    public func setUserProperty(_ key: String, value: String) {}
}

#if canImport(PostHog)
// Real implementation lands in v1.1 once the user opts in via Settings.
// import PostHog
// public final class PostHogAnalyticsService: AnalyticsService { ... }
#endif
