import Foundation
import BuddyCore

/// Glue between `ConnectivityService` and a `GameStateReducer`. The view
/// model for each game owns one of these and pumps inputs through it.
///
/// v1 is a thin scaffold — Phase 4-6 will fill in per-game wiring. The
/// service is kept here so the lobby can construct + hand off a session
/// without each game's view model touching the bridge directly.
@MainActor
final class GameSessionService: ObservableObject {

    @Published private(set) var session: GameSession?

    func start(kind: GameKind, host: Peer, guest: Peer, transport: Transport) {
        session = GameSession(
            id: UUID(),
            kind: kind,
            host: host,
            guest: guest,
            transport: transport,
            startedAt: Date()
        )
    }

    func end() { session = nil }
}
