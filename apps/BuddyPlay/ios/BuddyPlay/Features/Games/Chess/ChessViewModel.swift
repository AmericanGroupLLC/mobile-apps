import Foundation
import Combine
import BuddyCore

/// View model for `ChessScreen`. Holds the current `ChessState` and routes
/// taps through `ChessRules.reduce`.
///
/// In a 2-device session the host's view model owns the authoritative
/// state; the guest's view model receives state snapshots from the
/// connectivity layer and renders them. v1 ships local-only play first;
/// the wire-up to `GameSessionService` lands together with the
/// connectivity adapters.
@MainActor
final class ChessViewModel: ObservableObject {

    @Published private(set) var state: ChessState
    @Published var selected: ChessSquare?
    @Published var legalDestinations: Set<ChessSquare> = []
    @Published var lastError: String?

    let host: Peer
    let guest: Peer

    init(host: Peer, guest: Peer) {
        self.host = host
        self.guest = guest
        self.state = ChessRules.initialState(host: host, guest: guest)
    }

    /// Tap handler. First tap selects a piece (and computes legal
    /// destinations); second tap on a legal destination commits the move.
    func tap(_ square: ChessSquare) {
        if let from = selected {
            if legalDestinations.contains(square) {
                commit(ChessMove(from: from, to: square, promotion: defaultPromotion(from: from, to: square)))
            } else if let piece = state.board[square], piece.color == state.sideToMove {
                select(square)
            } else {
                clearSelection()
            }
        } else {
            select(square)
        }
    }

    private func select(_ square: ChessSquare) {
        guard let piece = state.board[square], piece.color == state.sideToMove else {
            clearSelection()
            return
        }
        selected = square
        let allLegal = ChessRules.legalMoves(in: state, for: piece.color)
        legalDestinations = Set(allLegal.filter { $0.from == square }.map { $0.to })
    }

    private func clearSelection() {
        selected = nil
        legalDestinations = []
    }

    private func commit(_ move: ChessMove) {
        do {
            let step = try ChessRules.reduce(state, input: move)
            state = step.state
            clearSelection()
            SfxService.shared.playMove()
            if step.outcome != nil { SfxService.shared.playWin() }
        } catch {
            lastError = "\(error)"
            clearSelection()
        }
    }

    /// v1: always promote to queen automatically. v1.1 adds a picker.
    private func defaultPromotion(from: ChessSquare, to: ChessSquare) -> ChessPiece.Kind? {
        guard let p = state.board[from], p.kind == .pawn else { return nil }
        let promoRank = p.color == .white ? 7 : 0
        return to.rank == promoRank ? .queen : nil
    }

    var isInCheck: Bool { ChessRules.isInCheck(state, color: state.sideToMove) }
    var currentTurn: UUID? { ChessRules.currentTurn(state) }
}
