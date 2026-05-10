import SwiftUI
import BuddyCore

/// Host lobby. User picks a game (already chosen via `kind`), BuddyPlay
/// starts advertising on Wi-Fi + BLE, surfaces a 4-character pairing code.
struct HostLobbyScreen: View {
    let kind: GameKind

    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var connectivity: ConnectivityService
    @Environment(\.dismiss) private var dismiss

    @State private var pairingCode: String = HostLobbyScreen.makeCode()

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Text("Hosting \(kind.displayName)")
                    .font(.title2.bold())

                PairingCodeView(code: pairingCode)

                statusBlock

                Text("Ask your friend to open BuddyPlay → Join Nearby Game and tap your phone in the list.")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                Spacer()
                Button("Cancel", role: .destructive) {
                    connectivity.disconnect()
                    dismiss()
                }
            }
            .padding(20)
            .navigationTitle("Host")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await connectivity.host(displayName: settings.displayName)
            }
            .onDisappear { connectivity.disconnect() }
        }
    }

    private var statusBlock: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            switch connectivity.state {
            case .idle:
                Text("Idle")
            case .advertising(let via):
                Text("Advertising via \(via.displayName)…")
            case .scanning(let via):
                Text("Scanning via \(via.displayName)…")
            case .connecting(let p):
                Text("Connecting to \(p.displayName)…")
            case .connected(let peer, let via):
                Text("Connected to \(peer.displayName) via \(via.displayName)")
                    .bold()
            case .failed(let r):
                Text(r).foregroundStyle(.red)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private static func makeCode() -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        let chars = (0..<4).map { _ in alphabet.randomElement()! }
        return "BUDD-" + String(chars)
    }
}
