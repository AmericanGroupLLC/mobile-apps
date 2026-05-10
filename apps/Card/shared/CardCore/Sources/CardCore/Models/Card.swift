// Card — the single domain object. Mirrored case-for-case in
// android/core/src/main/java/com/americangroupllc/card/core/models/Card.kt
import Foundation

public enum CardKind: String, Codable, CaseIterable, Sendable {
    case note
    case task
    case reminder
}

public struct Card: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var text: String
    public var kind: CardKind
    public var reminderAt: Date?
    public var completedAt: Date?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        kind: CardKind = .note,
        reminderAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.kind = kind
        self.reminderAt = reminderAt
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isCompleted: Bool { completedAt != nil }
}
