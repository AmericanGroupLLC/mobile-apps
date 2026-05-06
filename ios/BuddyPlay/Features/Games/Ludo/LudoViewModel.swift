import Foundation
import Combine
import BuddyCore

@MainActor
final class LudoViewModel: ObservableObject {

    @Published private(set) var state: LudoState
    @Published var lastDieRoll: Int?
    @Published var lastError: String?

    let host: Peer
    let guest: Peer

    init(host: Peer, guest: Peer) {
        self.host = host
        self.guest = guest
        self.state = LudoRules.initialState(host: host, guest: guest)
    }

    /// Roll the die. Random 1..6 for v1; in a 2-device session the host
    /// rolls and broadcasts the result.
    func rollDie() {
        let die = Int.random(in: 1...6)
        lastDieRoll = die

        let player = state.sideToMove
        let legal = LudoRules.legalTokenIndices(in: state, player: player, die: die)
        if legal.isEmpty {
            commit(LudoMove(player: player, diceRoll: die, tokenIndex: nil))
        }
    }

    /// Move the indicated token using the most recent die roll.
    func moveToken(_ tokenIndex: Int) {
        guard let die = lastDieRoll else { return }
        commit(LudoMove(player: state.sideToMove, diceRoll: die, tokenIndex: tokenIndex))
    }

    private func commit(_ move: LudoMove) {
        do {
            let step = try LudoRules.reduce(state, input: move)
            state = step.state
            lastDieRoll = nil
            SfxService.shared.playMove()
            if step.outcome != nil { SfxService.shared.playWin() }
        } catch {
            lastError = "\(error)"
        }
    }

    var legalTokenIndices: [Int] {
        guard let die = lastDieRoll else { return [] }
        return LudoRules.legalTokenIndices(in: state, player: state.sideToMove, die: die)
    }

    var currentTurn: UUID? { LudoRules.currentTurn(state) }
}
