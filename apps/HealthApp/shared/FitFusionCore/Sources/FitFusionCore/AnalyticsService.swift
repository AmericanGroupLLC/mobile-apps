import Foundation
#if canImport(PostHog)
import PostHog
#endif

/// Privacy-first product analytics. Same opt-in design as
/// `CrashReportingService`: SDK only initializes when the user has opted in
/// AND a build-time `POSTHOG_API_KEY` is configured. **PostHog** is the
/// default backend because:
///   * Free tier covers 1M events/month
///   * Open source — can be self-hosted
///   * GDPR-friendly defaults; EU region available
///   * Single SDK gives feature flags + analytics + session replay
///
/// Mixpanel / Amplitude can be swapped in by replacing this wrapper while
/// keeping the public API identical (`track`, `identify`, etc.).
@MainActor
public final class AnalyticsService: ObservableObject {

    public static let shared = AnalyticsService()
    public static let optInKey = "analyticsEnabled"

    @Published public var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.optInKey) }
    }

    private(set) public var isStarted = false

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.optInKey)
    }

    public static func resolveAPIKey() -> String? {
        if let env = ProcessInfo.processInfo.environment["POSTHOG_API_KEY"],
           !env.isEmpty { return env }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey")
            as? String, !plist.isEmpty { return plist }
        return nil
    }

    public static func resolveHost() -> String {
        if let env = ProcessInfo.processInfo.environment["POSTHOG_HOST"],
           !env.isEmpty { return env }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "PostHogHost")
            as? String, !plist.isEmpty { return plist }
        // EU region by default — switch to "https://us.i.posthog.com" or
        // your self-hosted URL if needed.
        return "https://eu.i.posthog.com"
    }

    public func bootstrapIfEnabled() {
        #if canImport(PostHog)
        guard isEnabled, !isStarted, let key = Self.resolveAPIKey() else { return }
        let config = PostHogConfig(apiKey: key, host: Self.resolveHost())
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false  // we'll fire screens manually
        #if os(iOS)
        // sessionReplay is iOS-only on the PostHog SDK; not available on watchOS.
        config.sessionReplay = false        // privacy-first; opt-in if needed
        #endif
        PostHogSDK.shared.setup(config)
        isStarted = true
        #endif
    }

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        #if canImport(PostHog)
        if enabled, !isStarted { bootstrapIfEnabled() }
        else if !enabled, isStarted { PostHogSDK.shared.optOut(); isStarted = false }
        #endif
    }

    /// Fire a feature-adoption event. Properties stay non-PII by convention.
    public func track(_ event: String, properties: [String: Any]? = nil) {
        #if canImport(PostHog)
        guard isStarted else { return }
        PostHogSDK.shared.capture(event, properties: properties)
        #endif
    }

    /// Optional: identify the user (only call after they sign in — not for
    /// guests). Use a hashed/anonymous id, never the raw email.
    public func identify(distinctId: String,
                         properties: [String: Any]? = nil) {
        #if canImport(PostHog)
        guard isStarted else { return }
        PostHogSDK.shared.identify(distinctId, userProperties: properties)
        #endif
    }

    public func screen(_ screen: String, properties: [String: Any]? = nil) {
        #if canImport(PostHog)
        guard isStarted else { return }
        PostHogSDK.shared.screen(screen, properties: properties)
        #endif
    }

    public func reset() {
        #if canImport(PostHog)
        if isStarted { PostHogSDK.shared.reset() }
        #endif
    }
}

/// Centralised event names. Keeps the analytics taxonomy consistent across
/// platforms — Android + Expo should use the same string literals.
public enum AnalyticsEvent {
    public static let onboardingStarted    = "onboarding_started"
    public static let onboardingCompleted  = "onboarding_completed"
    public static let guestModeChosen      = "guest_mode_chosen"
    public static let signInCompleted      = "sign_in_completed"
    public static let workoutStarted       = "workout_started"
    public static let workoutCompleted     = "workout_completed"
    public static let mealLogged           = "meal_logged"
    public static let medicineAdded        = "medicine_added"
    public static let medicineDoseTaken    = "medicine_dose_taken"
    public static let bioAgeEstimated      = "bio_age_estimated"
    public static let exportTriggered      = "data_export_triggered"
    public static let eraseAllConfirmed    = "data_erase_confirmed"
}
