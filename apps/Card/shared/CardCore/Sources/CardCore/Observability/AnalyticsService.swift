// AnalyticsService — canImport-gated stub. When PostHog is present at compile
// time, the wrapper forwards events; otherwise it is a no-op so CardCore
// builds without any third-party deps. See SENTRY.md to actually wire PostHog.
import Foundation

/// The capture surface that triggered the event. Distinguishing per-surface
/// latency / conversion is the only reason this enum exists.
public enum Surface: String, Sendable {
    case app
    case shareExtension = "share_extension"
    case watch
    case complication
    case tile
}

public enum AnalyticsEvent: Sendable {
    case cardCaptured(surface: Surface, kind: CardKind)
    case cardConverted(from: CardKind, to: CardKind)
    case reminderScheduled(surface: Surface, delayMinutes: Int)
    case reminderFired(surface: Surface)
    case cardDeleted(kind: CardKind)
    case settingsToggled(name: String, enabled: Bool)
    case onboardingCompleted

    public var name: String {
        switch self {
        case .cardCaptured:        return "card_captured"
        case .cardConverted:       return "card_converted"
        case .reminderScheduled:   return "reminder_scheduled"
        case .reminderFired:       return "reminder_fired"
        case .cardDeleted:         return "card_deleted"
        case .settingsToggled:     return "settings_toggled"
        case .onboardingCompleted: return "onboarding_completed"
        }
    }

    public var properties: [String: String] {
        switch self {
        case .cardCaptured(let s, let k):
            return ["surface": s.rawValue, "kind": k.rawValue]
        case .cardConverted(let f, let t):
            return ["from_kind": f.rawValue, "to_kind": t.rawValue]
        case .reminderScheduled(let s, let m):
            return ["surface": s.rawValue, "delay_minutes": String(m)]
        case .reminderFired(let s):
            return ["surface": s.rawValue]
        case .cardDeleted(let k):
            return ["kind": k.rawValue]
        case .settingsToggled(let n, let e):
            return ["name": n, "enabled": String(e)]
        case .onboardingCompleted:
            return [:]
        }
    }
}

public protocol AnalyticsTransport: AnyObject {
    func track(name: String, properties: [String: String])
}

public final class AnalyticsService {
    public static let shared = AnalyticsService()
    public var optedIn: Bool = false
    private var transport: AnalyticsTransport?

    public init() {}

    public func attach(transport: AnalyticsTransport?) { self.transport = transport }

    public func track(_ event: AnalyticsEvent) {
        guard optedIn, let t = transport else { return }
        t.track(name: event.name, properties: event.properties)
    }
}

#if canImport(PostHog)
import PostHog
extension AnalyticsService {
    public func usePostHog(apiKey: String, host: String = "https://us.i.posthog.com") {
        let cfg = PostHogConfig(apiKey: apiKey, host: host)
        PostHogSDK.shared.setup(cfg)
        attach(transport: PostHogTransport())
    }
}
private final class PostHogTransport: AnalyticsTransport {
    func track(name: String, properties: [String: String]) {
        PostHogSDK.shared.capture(name, properties: properties as [String: Any])
    }
}
#endif
