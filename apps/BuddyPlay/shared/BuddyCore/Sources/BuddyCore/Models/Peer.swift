import Foundation

/// A peer is another BuddyPlay device the user can play with. The `id` is
/// generated once on first launch and persisted in `device.json`. It's not
/// a user identity — it's just a stable handle so the rivalry store can
/// keep tallies across sessions with the same person.
public struct Peer: Codable, Hashable, Sendable {
    public let id: UUID
    public var displayName: String
    public var platform: Platform
    public var lastSeenAt: Date

    public init(id: UUID, displayName: String, platform: Platform, lastSeenAt: Date) {
        self.id = id
        self.displayName = displayName
        self.platform = platform
        self.lastSeenAt = lastSeenAt
    }

    public enum Platform: String, Codable, Sendable {
        case ios
        case android
    }
}
