import Foundation

/// Layer 5 leaderboard client. Reads ranked entries for a given challenge from
/// the Express backend and (optionally, off-by-default) publishes the user's
/// own score to a Game Center leaderboard. The Game Center path is gated
/// behind `enableGameCenterPublishing` so development builds don't need App
/// Store Connect setup.
@MainActor
public final class LeaderboardClient: ObservableObject {

    public static let shared = LeaderboardClient()
    public init() {}

    /// Flip to `true` when an App Store Connect leaderboard is configured.
    public var enableGameCenterPublishing = false

    public struct Entry: Identifiable, Hashable, Decodable {
        public let id: Int
        public let user_id: Int
        public let name: String
        public let email: String
        public let score: Double
        public let updated_at: String

        public var rankBadge: String {
            switch score {
            case 1000...: return "\u{1F947}"
            case 500...:  return "\u{1F948}"
            case 100...:  return "\u{1F949}"
            default:      return "\u{1F4AA}"
            }
        }
    }

    public struct LeaderboardResponse: Decodable { public let entries: [Entry] }

    public func entries(for challengeId: Int) async throws -> [Entry] {
        let response: LeaderboardResponse = try await APIClient.shared.sendRequest(
            path: "/api/social/leaderboard?challenge=\(challengeId)",
            as: LeaderboardResponse.self
        )
        return response.entries
    }

    public func submit(score: Double, challengeId: Int) async {
        struct Body: Encodable { let challenge_id: Int; let score: Double }
        _ = try? await APIClient.shared.sendRequest(
            path: "/api/social/leaderboard/score",
            method: "POST",
            body: Body(challenge_id: challengeId, score: score),
            as: NoOpResponse.self
        )
        // Optional Game Center publish \u{2014} off by default.
        if enableGameCenterPublishing {
            // Stubbed; wire up `GKLeaderboard.submitScore(...)` once an
            // App Store Connect leaderboard is configured.
        }
    }
}
