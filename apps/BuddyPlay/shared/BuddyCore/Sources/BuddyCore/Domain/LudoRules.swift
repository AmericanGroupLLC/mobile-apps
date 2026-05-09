import Foundation

/// Pure Ludo (Dice Kingdom) rules. 2-player, 4 tokens each, deterministic
/// dice rolls supplied via `LudoMove.diceRoll` (so the host can broadcast
/// the same rolls to the guest).
///
/// Board model (simplified for v1):
///   - 52 main-track squares numbered 0..51, shared by both players.
///   - Each player has a "home column" of 6 squares numbered 100..105 (red)
///     and 200..205 (blue).
///   - Tokens start in the base (position = -1).
///   - Red enters the main track at square 0; blue at square 26.
///   - Red's home column entry is square 50; blue's is square 24.
///   - Win = all 4 tokens on the final home square (105 / 205).
///   - Rolling 6 grants an extra turn; rolling three 6s in a row forfeits.
///   - Capture: landing on opponent token (not in home column or "safe"
///     squares 0,8,13,21,26,34,39,47) sends them home (-1).
public enum LudoRules: GameStateReducer {
    public typealias State = LudoState
    public typealias Input = LudoMove

    public static func initialState(host: Peer, guest: Peer) -> LudoState {
        LudoState(
            red: host.id, blue: guest.id,
            tokens: [
                host.id:  [-1, -1, -1, -1],
                guest.id: [-1, -1, -1, -1],
            ],
            sideToMove: host.id,
            consecutiveSixes: 0,
            lastDie: nil,
            outcome: nil
        )
    }

    public static func reduce(_ state: LudoState, input move: LudoMove) throws -> Step {
        if state.outcome != nil { throw Error.gameOver }
        guard move.player == state.sideToMove else { throw Error.wrongTurn }
        let die = move.diceRoll
        guard (1...6).contains(die) else { throw Error.illegal("die \(die) not in 1..6") }

        var s = state
        s.lastDie = die

        // Track consecutive sixes.
        if die == 6 {
            s.consecutiveSixes += 1
            if s.consecutiveSixes >= 3 {
                // Three sixes in a row — turn forfeited, no token moves.
                s.consecutiveSixes = 0
                s.sideToMove = opponent(of: move.player, in: s)
                return (s, nil)
            }
        } else {
            s.consecutiveSixes = 0
        }

        // Resolve token movement.
        if let idx = move.tokenIndex {
            try advanceToken(&s, player: move.player, tokenIndex: idx, by: die)
        } else {
            // Pass turn intentionally (no legal move possible).
            guard !hasAnyLegalMove(s, player: move.player, die: die) else {
                throw Error.illegal("must move a token (a legal move exists)")
            }
        }

        // Win check.
        if s.tokens[move.player]!.allSatisfy({ $0 == finalHome(for: move.player, in: s) }) {
            s.outcome = .winner(move.player)
            return (s, .winner(move.player))
        }

        // Turn rotation: rolling a 6 grants extra turn.
        if die != 6 {
            s.sideToMove = opponent(of: move.player, in: s)
        }
        return (s, nil)
    }

    public static func isFinal(_ state: LudoState) -> Bool {
        state.outcome != nil
    }

    public static func currentTurn(_ state: LudoState) -> UUID? {
        state.outcome != nil ? nil : state.sideToMove
    }

    // MARK: - Helpers

    public static func legalTokenIndices(in state: LudoState, player: UUID, die: Int) -> [Int] {
        var out: [Int] = []
        for (idx, pos) in state.tokens[player]!.enumerated() {
            if pos == -1 {
                if die == 6 { out.append(idx) }
                continue
            }
            if pos == finalHome(for: player, in: state) { continue }
            // Cannot overshoot final home.
            let target = projectedPosition(player: player, in: state, from: pos, advancing: die)
            if target != nil { out.append(idx) }
        }
        return out
    }

    private static func hasAnyLegalMove(_ s: LudoState, player: UUID, die: Int) -> Bool {
        !legalTokenIndices(in: s, player: player, die: die).isEmpty
    }

    private static func opponent(of p: UUID, in s: LudoState) -> UUID {
        p == s.red ? s.blue : s.red
    }

    /// 105 for red, 205 for blue.
    private static func finalHome(for player: UUID, in s: LudoState) -> Int {
        player == s.red ? 105 : 205
    }

    /// Advance a token. Throws if the move is illegal (target overshoots
    /// final home, or token is in base and die isn't 6, etc.).
    private static func advanceToken(_ s: inout LudoState, player: UUID, tokenIndex: Int, by die: Int) throws {
        var tokens = s.tokens[player]!
        let pos = tokens[tokenIndex]
        if pos == -1 {
            guard die == 6 else { throw Error.illegal("need a 6 to leave base") }
            let entry = entrySquare(for: player, in: s)
            tokens[tokenIndex] = entry
            s.tokens[player] = tokens
            applyCapture(&s, player: player, landingPosition: entry)
            return
        }
        guard let target = projectedPosition(player: player, in: s, from: pos, advancing: die) else {
            throw Error.illegal("would overshoot final home")
        }
        tokens[tokenIndex] = target
        s.tokens[player] = tokens
        applyCapture(&s, player: player, landingPosition: target)
    }

    private static func projectedPosition(player: UUID, in s: LudoState, from pos: Int, advancing die: Int) -> Int? {
        let homeEntry = homeColumnEntrySquare(for: player, in: s)
        let homeBase = player == s.red ? 100 : 200
        let homeFinal = finalHome(for: player, in: s)

        // Already in home column.
        if (homeBase...homeFinal).contains(pos) {
            let target = pos + die
            return target <= homeFinal ? target : nil
        }

        // On main track.
        var stepsLeft = die
        var current = pos
        while stepsLeft > 0 {
            // If next step crosses the home-column entry, divert into home.
            if current == homeEntry {
                let target = homeBase + stepsLeft - 1
                return target <= homeFinal ? target : nil
            }
            current = (current + 1) % 52
            stepsLeft -= 1
        }
        return current
    }

    private static func entrySquare(for player: UUID, in s: LudoState) -> Int {
        player == s.red ? 0 : 26
    }
    private static func homeColumnEntrySquare(for player: UUID, in s: LudoState) -> Int {
        player == s.red ? 50 : 24
    }

    private static let safeSquares: Set<Int> = [0, 8, 13, 21, 26, 34, 39, 47]

    /// If `landingPosition` is on the main track and not safe, knock any
    /// opposing tokens occupying it back to base.
    private static func applyCapture(_ s: inout LudoState, player: UUID, landingPosition pos: Int) {
        guard pos < 100 else { return }            // home column = no capture
        guard !safeSquares.contains(pos) else { return }
        let opp = opponent(of: player, in: s)
        var oppTokens = s.tokens[opp]!
        for i in 0..<oppTokens.count where oppTokens[i] == pos {
            oppTokens[i] = -1
        }
        s.tokens[opp] = oppTokens
    }
}

// MARK: - Types

public struct LudoMove: Codable, Equatable, Sendable {
    public let player: UUID
    public let diceRoll: Int
    /// `nil` means "no legal move; pass turn". Otherwise 0..3.
    public let tokenIndex: Int?

    public init(player: UUID, diceRoll: Int, tokenIndex: Int?) {
        self.player = player
        self.diceRoll = diceRoll
        self.tokenIndex = tokenIndex
    }
}

public struct LudoState: Codable, Equatable, Sendable {
    public let red: UUID
    public let blue: UUID
    public var tokens: [UUID: [Int]]      // 4 token positions per player
    public var sideToMove: UUID
    public var consecutiveSixes: Int
    public var lastDie: Int?
    public var outcome: Outcome?

    public enum Outcome: Codable, Equatable, Sendable {
        case winner(UUID)
        case resignation(loser: UUID)
    }
}
