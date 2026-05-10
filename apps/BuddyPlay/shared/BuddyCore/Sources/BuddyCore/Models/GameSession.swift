import Foundation

/// One ongoing game between two peers. Decided once via `HostElection` and
/// then immutable for the duration of the match.
public struct GameSession: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let kind: GameKind
    public let host: Peer
    public let guest: Peer
    public let transport: Transport
    public let startedAt: Date

    public init(
        id: UUID,
        kind: GameKind,
        host: Peer,
        guest: Peer,
        transport: Transport,
        startedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.host = host
        self.guest = guest
        self.transport = transport
        self.startedAt = startedAt
    }

    /// True if the local peer (identified by `localPeerId`) is the host.
    public func isLocalHost(_ localPeerId: UUID) -> Bool {
        host.id == localPeerId
    }

    /// The opponent of the local peer.
    public func opponent(of localPeerId: UUID) -> Peer {
        host.id == localPeerId ? guest : host
    }
}
