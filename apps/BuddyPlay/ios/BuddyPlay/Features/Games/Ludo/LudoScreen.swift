import SwiftUI
import BuddyCore

struct LudoScreen: View {
    @StateObject private var vm: LudoViewModel
    @Environment(\.dismiss) private var dismiss

    init(host: Peer, guest: Peer) {
        _vm = StateObject(wrappedValue: LudoViewModel(host: host, guest: guest))
    }

    var body: some View {
        VStack(spacing: 16) {
            statusBar
            LudoBoardView(vm: vm)
            controls
            Spacer()
        }
        .padding(16)
        .navigationTitle("Dice Kingdom")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusBar: some View {
        HStack {
            Text(currentName + "'s turn")
                .font(.headline)
            Spacer()
            if let outcome = vm.state.outcome, case .winner(let id) = outcome {
                let name = (id == vm.host.id) ? vm.host.displayName : vm.guest.displayName
                Text("\(name) wins!").foregroundStyle(.red).bold()
            }
        }
    }

    private var controls: some View {
        HStack {
            Button(action: { vm.rollDie() }) {
                HStack {
                    Image(systemName: "die.face.\(vm.lastDieRoll ?? 1).fill")
                        .font(.title)
                    if let die = vm.lastDieRoll {
                        Text("Rolled \(die) — tap a token to move")
                    } else {
                        Text("Roll the die")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.state.outcome != nil || vm.lastDieRoll != nil)
            Spacer()
            Button("Quit", role: .destructive) { dismiss() }
        }
    }

    private var currentName: String {
        guard let id = vm.currentTurn else { return "—" }
        return (id == vm.host.id) ? vm.host.displayName : vm.guest.displayName
    }
}
