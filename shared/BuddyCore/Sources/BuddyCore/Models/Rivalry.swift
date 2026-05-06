import Foundation

/// One cumulative head-to-head record against another peer, keyed by their
/// stable UUID. Persisted in `LocalRivalryStore`.
public struct Rivalry: Codable, Hashable, Sendable {
    public let opponentId: UUID
    public var opponentName: String
    public var perGame: [GameKind: Record]
    public var lastPlayedAt: Date

    public init(
        opponentId: UUID,
        opponentName: String,
        perGame: [GameKind: Record] = [:],
        lastPlayedAt: Date
    ) {
        self.opponentId = opponentId
        self.opponentName = opponentName
        self.perGame = perGame
        self.lastPlayedAt = lastPlayedAt
    }

    public struct Record: Codable, Hashable, Sendable {
        public var wins: Int
        public var losses: Int
        public var draws: Int

        public init(wins: Int = 0, losses: Int = 0, draws: Int = 0) {
            self.wins = wins
            self.losses = losses
            self.draws = draws
        }

        public var totalPlayed: Int { wins + losses + draws }
    }

    public mutating func record(_ outcome: Outcome, for kind: GameKind, at date: Date) {
        var rec = perGame[kind, default: Record()]
        switch outcome {
        case .win:  rec.wins += 1
        case .loss: rec.losses += 1
        case .draw: rec.draws += 1
        }
        perGame[kind] = rec
        lastPlayedAt = date
    }

    public enum Outcome: String, Codable, Sendable {
        case win, loss, draw
    }
}
