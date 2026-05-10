import Foundation

/// One of two profile types per install.
public struct Profile: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var kind: Kind
    /// PBKDF2-SHA256 hex digest of `pin + salt`. Only set when `kind == .kidSafe`.
    public var pinHash: String?
    /// Hex-encoded random salt used with `pinHash`.
    public var pinSalt: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        kind: Kind,
        pinHash: String? = nil,
        pinSalt: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.pinHash = pinHash
        self.pinSalt = pinSalt
        self.createdAt = createdAt
    }

    public enum Kind: String, Codable, Sendable {
        case adult
        case kidSafe
    }
}
