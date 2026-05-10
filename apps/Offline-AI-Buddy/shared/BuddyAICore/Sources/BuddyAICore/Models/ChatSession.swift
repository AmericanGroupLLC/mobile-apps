import Foundation

public struct ChatSession: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let profileId: UUID
    public var language: Language
    public var kind: Kind
    public var messages: [ChatMessage]
    public let startedAt: Date

    public init(
        id: UUID = UUID(),
        profileId: UUID,
        language: Language,
        kind: Kind,
        messages: [ChatMessage] = [],
        startedAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.language = language
        self.kind = kind
        self.messages = messages
        self.startedAt = startedAt
    }

    public enum Kind: String, Codable, Sendable, CaseIterable {
        case chat
        case roast
        case dailyChallenge
        case partyQuestions
        case gameCoach
        case translate

        public var displayName: String {
            switch self {
            case .chat:           return "Chat"
            case .roast:          return "Roast"
            case .dailyChallenge: return "Daily Challenge"
            case .partyQuestions: return "Party Questions"
            case .gameCoach:      return "Game Coach"
            case .translate:      return "Translate"
            }
        }

        /// Whether this mode is shown in Kid-safe profile.
        public var availableInKidSafe: Bool {
            switch self {
            case .roast: return false
            default: return true
            }
        }
    }
}
