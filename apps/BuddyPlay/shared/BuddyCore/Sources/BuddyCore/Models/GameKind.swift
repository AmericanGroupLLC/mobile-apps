import Foundation

/// The catalogue of games BuddyPlay knows about. Adding game #4 (e.g.
/// Tic-Tac-Toe) is one new case here + one new feature module.
public enum GameKind: String, Codable, CaseIterable, Sendable {
    case chess
    case ludo
    case racer

    /// Human-readable name surfaced in the UI.
    public var displayName: String {
        switch self {
        case .chess: return "Royal Chess"
        case .ludo:  return "Dice Kingdom"
        case .racer: return "Mini Racer"
        }
    }

    /// Whether the game can run over BLE. Mini Racer needs Wi-Fi or Hotspot.
    public var supportsBle: Bool {
        switch self {
        case .chess, .ludo: return true
        case .racer:        return false
        }
    }

    /// Number of players supported in v1.
    public var playerCount: Int {
        switch self {
        case .chess, .ludo, .racer: return 2
        }
    }
}
