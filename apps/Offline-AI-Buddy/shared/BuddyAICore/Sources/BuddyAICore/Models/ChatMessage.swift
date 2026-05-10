import Foundation

public struct ChatMessage: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var role: Role
    public var text: String
    public var ts: Date

    public init(id: UUID = UUID(), role: Role, text: String, ts: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.ts = ts
    }

    public enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }
}
