// AnalyticsService — canImport-gated stub. When PostHog is present at compile
// time, the wrapper forwards events; otherwise it is a no-op so PocketCore
// builds without any third-party deps.
import Foundation

public enum Tool: String, Sendable {
    case clock, calculator, measure, compass, level
}

public enum AnalyticsEvent: Sendable {
    case opened(Tool)
    case settingsToggled(name: String, enabled: Bool)
    case onboardingCompleted
    case alarmCreated
    case alarmFired

    public var name: String {
        switch self {
        case .opened:               return "tool_opened"
        case .settingsToggled:      return "settings_toggled"
        case .onboardingCompleted:  return "onboarding_completed"
        case .alarmCreated:         return "alarm_created"
        case .alarmFired:           return "alarm_fired"
        }
    }

    public var properties: [String: String] {
        switch self {
        case .opened(let t):                          return ["tool": t.rawValue]
        case .settingsToggled(let n, let e):          return ["name": n, "enabled": String(e)]
        default:                                       return [:]
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
