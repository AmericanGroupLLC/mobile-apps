import Foundation

/// Deterministic host election for a 2-peer session. Both peers run this
/// locally on the same `(a, b)` tuple and agree on the host without
/// negotiating.
///
/// Algorithm:
///   1. The peer with the lexicographically SMALLER `id.uuidString` wins.
///   2. Tie-break (impossible with v4 UUIDs but kept for theoretical
///      completeness): iOS wins over Android.
public enum HostElection {

    public static func host(between a: Peer, _ b: Peer) -> Peer {
        let aStr = a.id.uuidString
        let bStr = b.id.uuidString
        if aStr < bStr { return a }
        if bStr < aStr { return b }
        // Same UUID — extremely unlikely. Tie-break by platform.
        switch (a.platform, b.platform) {
        case (.ios, .android): return a
        case (.android, .ios): return b
        default:                return a
        }
    }

    /// Convenience: which of the two is the guest.
    public static func guest(between a: Peer, _ b: Peer) -> Peer {
        host(between: a, b).id == a.id ? b : a
    }
}
