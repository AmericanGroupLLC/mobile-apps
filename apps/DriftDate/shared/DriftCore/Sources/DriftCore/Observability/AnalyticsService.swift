import Foundation

/// Where an event came from. Mirrors the Kotlin enum.
public enum Surface: String, Sendable, Codable {
    case app
    case notificationExtension = "notification_extension"
    case watch
    case complication
    case tile
}

/// Drift's canonical event taxonomy. Mirrors the Kotlin sealed class.
public enum AnalyticsEvent: Equatable, Sendable {
    case onboardingCompleted
    case waveSent(layer: Layer, surface: Surface)
    case waveMatched(layer: Layer, timeToMatchSeconds: Int)
    case chatScreenOpen(conversationId: UUID, tone: Tone)
    case replySuggestionUsed(tone: Tone, kind: ReplyKind)
    case replySuggestionDismissed(tone: Tone)
    case verificationStarted
    case verificationSucceeded(similarityPct: Int)
    case verificationFailed(reason: String)
    case reportFiled(reason: String)
    case blockUser
    case settingsToggled(name: String, enabled: Bool)
    case layerSwitched(from: Layer, to: Layer)
    case appOpenedFromPush(pushType: PushType)

    public enum ReplyKind: String, Sendable, Codable {
        case casual, context, playful
    }
    public enum PushType: String, Sendable, Codable {
        case match, message
    }

    public var name: String {
        switch self {
        case .onboardingCompleted:        return "onboarding_completed"
        case .waveSent:                   return "wave_sent"
        case .waveMatched:                return "wave_matched"
        case .chatScreenOpen:             return "chat_screen_open"
        case .replySuggestionUsed:        return "reply_suggestion_used"
        case .replySuggestionDismissed:   return "reply_suggestion_dismissed"
        case .verificationStarted:        return "verification_started"
        case .verificationSucceeded:      return "verification_succeeded"
        case .verificationFailed:         return "verification_failed"
        case .reportFiled:                return "report_filed"
        case .blockUser:                  return "block_user"
        case .settingsToggled:            return "settings_toggled"
        case .layerSwitched:              return "layer_switched"
        case .appOpenedFromPush:          return "app_opened_from_push"
        }
    }

    public var properties: [String: String] {
        switch self {
        case .onboardingCompleted, .verificationStarted, .blockUser:
            return [:]
        case .waveSent(let layer, let surface):
            return ["layer": layer.rawValue, "surface": surface.rawValue]
        case .waveMatched(let layer, let secs):
            return ["layer": layer.rawValue, "time_to_match_seconds": String(secs)]
        case .chatScreenOpen(let id, let tone):
            return ["conversation_id": id.uuidString, "tone": tone.rawValue]
        case .replySuggestionUsed(let tone, let kind):
            return ["tone": tone.rawValue, "kind": kind.rawValue]
        case .replySuggestionDismissed(let tone):
            return ["tone": tone.rawValue]
        case .verificationSucceeded(let pct):
            return ["similarity_pct": String(pct)]
        case .verificationFailed(let reason):
            return ["reason": reason]
        case .reportFiled(let reason):
            return ["reason": reason]
        case .settingsToggled(let name, let enabled):
            return ["name": name, "enabled": enabled ? "true" : "false"]
        case .layerSwitched(let from, let to):
            return ["from_layer": from.rawValue, "to_layer": to.rawValue]
        case .appOpenedFromPush(let pushType):
            return ["push_type": pushType.rawValue]
        }
    }
}

public protocol AnalyticsTransport: AnyObject {
    func track(name: String, properties: [String: String])
}

public final class AnalyticsService {
    public static let shared = AnalyticsService()

    public var optedIn: Bool = false
    private weak var transport: AnalyticsTransport?

    public func attach(_ transport: AnalyticsTransport?) { self.transport = transport }

    public func track(_ event: AnalyticsEvent) {
        guard optedIn, let transport else { return }
        transport.track(name: event.name, properties: event.properties)
    }

    #if canImport(PostHog)
    /// Wires up PostHog. Called from the host app's AppDelegate when
    /// `POSTHOG_API_KEY` is non-empty.
    public func usePostHog(apiKey: String, host: String) {
        // The app target is responsible for creating the actual PostHog
        // configuration. This stub keeps the API surface stable on
        // open-source builds with no SDK installed.
    }
    #endif
}
