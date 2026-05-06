import Foundation

public struct Conversation: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let profileAId: UUID
    public let profileBId: UUID
    public var tone: Tone
    public var lastReadA: Date?
    public var lastReadB: Date?
    public var mutedByA: Bool
    public var mutedByB: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        profileAId: UUID,
        profileBId: UUID,
        tone: Tone = .slow,
        lastReadA: Date? = nil,
        lastReadB: Date? = nil,
        mutedByA: Bool = false,
        mutedByB: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileAId = profileAId
        self.profileBId = profileBId
        self.tone = tone
        self.lastReadA = lastReadA
        self.lastReadB = lastReadB
        self.mutedByA = mutedByA
        self.mutedByB = mutedByB
        self.createdAt = createdAt
    }

    public var profileIds: [UUID] { [profileAId, profileBId] }
}

public struct Message: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let conversationId: UUID
    public let authorId: UUID
    public let text: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        conversationId: UUID,
        authorId: UUID,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.authorId = authorId
        self.text = text
        self.createdAt = createdAt
    }
}

/// Returned by the `reply-suggest` Edge Function. Never persisted.
public struct ReplySuggestion: Codable, Equatable, Sendable {
    public let casual: String
    public let context: String
    public let playful: String
    public let tone: Tone

    public init(casual: String, context: String, playful: String, tone: Tone) {
        self.casual = casual
        self.context = context
        self.playful = playful
        self.tone = tone
    }
}
