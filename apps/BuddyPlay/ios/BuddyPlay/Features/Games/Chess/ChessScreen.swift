import SwiftUI
import BuddyCore

struct ChessScreen: View {
    @StateObject private var vm: ChessViewModel
    @Environment(\.dismiss) private var dismiss

    init(host: Peer, guest: Peer) {
        _vm = StateObject(wrappedValue: ChessViewModel(host: host, guest: guest))
    }

    var body: some View {
        VStack(spacing: 16) {
            statusBar
            ChessBoardView(vm: vm)
                .padding(8)
            controls
        }
        .padding(16)
        .navigationTitle("Royal Chess")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusBar: some View {
        HStack {
            playerChip(vm.host, isCurrent: vm.currentTurn == vm.host.id)
            Spacer()
            if let outcome = vm.state.outcome {
                Text(outcomeText(outcome))
                    .font(.headline)
                    .foregroundStyle(.red)
            } else if vm.isInCheck {
                Text("Check!").font(.headline).foregroundStyle(.orange)
            }
            Spacer()
            playerChip(vm.guest, isCurrent: vm.currentTurn == vm.guest.id)
        }
    }

    private func playerChip(_ peer: Peer, isCurrent: Bool) -> some View {
        VStack {
            Image(systemName: peer.id == vm.host.id ? "circle" : "circle.fill")
                .font(.title3)
            Text(peer.displayName).font(.caption)
        }
        .padding(8)
        .background(isCurrent ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var controls: some View {
        HStack {
            Button("Resign", role: .destructive) {
                dismiss()
            }
            Spacer()
            if vm.state.outcome != nil {
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func outcomeText(_ o: ChessState.Outcome) -> String {
        switch o {
        case .checkmate(let winner):
            let name = (winner == vm.host.id) ? vm.host.displayName : vm.guest.displayName
            return "\(name) wins by checkmate"
        case .stalemate:           return "Stalemate · draw"
        case .fiftyMoveRule:       return "50-move rule · draw"
        case .threefoldRepetition: return "Threefold repetition · draw"
        case .resignation(let loser):
            let name = (loser == vm.host.id) ? vm.host.displayName : vm.guest.displayName
            return "\(name) resigned"
        }
    }
}
