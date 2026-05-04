import Foundation
#if canImport(Sentry)
import Sentry
#endif

/// Privacy-first wrapper around Sentry. The SDK is **only** initialized when
/// BOTH conditions are true:
///   * The user has opted in via Settings -> "Send crash reports"
///   * A build-time `SENTRY_DSN` is configured (Info.plist key or env var)
///
/// When either condition is false, every method here is a no-op. No data
/// ever leaves the device. Default state is **disabled** so Guest Mode users
/// don't get any background telemetry by surprise.
@MainActor
public final class CrashReportingService: ObservableObject {

    public static let shared = CrashReportingService()

    public static let optInKey = "crashReportsEnabled"

    /// Persisted opt-in flag. Surface this via a Settings toggle.
    @Published public var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.optInKey) }
    }

    private(set) public var isStarted: Bool = false

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.optInKey)
    }

    /// Read the DSN from (in order): the env var `SENTRY_DSN`, then the
    /// Info.plist key `SentryDSN`. Returns `nil` if neither is set.
    public static func resolveDSN() -> String? {
        if let env = ProcessInfo.processInfo.environment["SENTRY_DSN"],
           !env.isEmpty {
            return env
        }
        if let plistDSN = Bundle.main.object(forInfoDictionaryKey: "SentryDSN")
            as? String, !plistDSN.isEmpty {
            return plistDSN
        }
        return nil
    }

    /// Call from `FitFusionApp.init` (or `.task` after auth is restored).
    /// Safe to call multiple times \u2014 it short-circuits when already started.
    public func bootstrapIfEnabled(release: String,
                                   environment: String = "production") {
        #if canImport(Sentry)
        guard isEnabled, !isStarted, let dsn = Self.resolveDSN() else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.releaseName = release
            options.environment = environment
            // Privacy: never collect PII; sample 100% errors but ZERO traces.
            options.tracesSampleRate = 0
            options.attachStacktrace = true
            options.sendDefaultPii = false
            options.maxBreadcrumbs = 50
            options.beforeSend = { event in
                // Strip any user-identifiable email-shaped strings
                event.user = nil
                return event
            }
        }
        isStarted = true
        #endif
    }

    /// Toggle from Settings. Stops the SDK if user opts out at runtime.
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        #if canImport(Sentry)
        if !enabled, isStarted {
            SentrySDK.close()
            isStarted = false
        }
        #endif
    }

    /// Manual capture for non-fatal errors caught by the app.
    public func captureError(_ error: Error,
                             extras: [String: Any]? = nil) {
        #if canImport(Sentry)
        guard isStarted else { return }
        SentrySDK.capture(error: error) { scope in
            extras?.forEach { scope.setExtra(value: $0.value, key: $0.key) }
        }
        #endif
    }

    /// Manual capture for breadcrumb-style messages.
    public func captureMessage(_ message: String,
                               level: SentryLevelMirror = .info) {
        #if canImport(Sentry)
        guard isStarted else { return }
        let sentryLevel: SentryLevel
        switch level {
        case .debug:   sentryLevel = .debug
        case .info:    sentryLevel = .info
        case .warning: sentryLevel = .warning
        case .error:   sentryLevel = .error
        case .fatal:   sentryLevel = .fatal
        }
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(sentryLevel)
        }
        #endif
    }
}

/// Sentry-independent level enum so callers don't have to `import Sentry`.
public enum SentryLevelMirror {
    case debug, info, warning, error, fatal
}
