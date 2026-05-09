import SwiftUI
import BuddyCore

/// Simplified linear board for v1: shows each player's 4 tokens as
/// progress markers along their path. Phase 6+ can replace with a
/// proper cross board if there's time.
struct LudoBoardView: View {
    @ObservedObject var vm: LudoViewModel

    var body: some View {
        VStack(spacing: 18) {
            playerLane(player: vm.host, color: .red,  label: vm.host.displayName)
            playerLane(player: vm.guest, color: .blue, label: vm.guest.displayName)
        }
    }

    private func playerLane(player: Peer, color: Color, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 12, height: 12)
                Text(label).font(.headline)
                Spacer()
                Text("\(homeCount(player)) / 4 home")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { idx in
                    let pos = vm.state.tokens[player.id]?[idx] ?? -1
                    let isLegal = (player.id == vm.state.sideToMove) && vm.legalTokenIndices.contains(idx)
                    TokenChip(position: pos, color: color, isLegalToMove: isLegal)
                        .onTapGesture {
                            if isLegal { vm.moveToken(idx) }
                        }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func homeCount(_ p: Peer) -> Int {
        let target = (p.id == vm.host.id) ? 105 : 205
        return vm.state.tokens[p.id]?.filter { $0 == target }.count ?? 0
    }
}

private struct TokenChip: View {
    let position: Int
    let color: Color
    let isLegalToMove: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(isLegalToMove ? Color.accentColor : .clear, lineWidth: 3)
                )
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 64)
    }

    private var label: String {
        switch position {
        case -1:                return "Base"
        case 100...105, 200...205: return "Home"
        default:                return "Sq \(position)"
        }
    }
}
