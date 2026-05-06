import Foundation

/// Pure `(state, input) -> state` reducer. Each game module conforms to this
/// with its own `State` and `Input` types. The connectivity layer just
/// routes inputs in and broadcasts the new state out.
public protocol GameStateReducer {
    associatedtype State: Codable & Equatable & Sendable
    associatedtype Input: Codable & Equatable & Sendable

    /// The starting state for a new game between two peers.
    static func initialState(host: Peer, guest: Peer) -> State

    /// Apply a single input. Returns the new state and an optional
    /// "outcome" (win/loss/draw + winner peerId) when the game just ended.
    /// Throws `Error.illegal` if the input violates game rules.
    static func reduce(_ state: State, input: Input) throws -> Step

    /// Convenience: is the game over?
    static func isFinal(_ state: State) -> Bool

    /// The peerId whose turn it currently is, or `nil` for non-turn-based
    /// games (Racer).
    static func currentTurn(_ state: State) -> UUID?

    typealias Step = (state: State, outcome: Outcome?)

    enum Error: Swift.Error, Equatable {
        case illegal(String)
        case wrongTurn
        case gameOver
    }

    enum Outcome: Equatable, Sendable {
        case winner(UUID)
        case draw
    }
}
