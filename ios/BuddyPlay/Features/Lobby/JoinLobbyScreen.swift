import SwiftUI
import BuddyCore

/// Join lobby. Auto-scans every ~5 s while foregrounded; tapping a host
/// opens the code-confirm sheet.
struct JoinLobbyScreen: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var connectivity: ConnectivityService
    @Environment(\.dismiss) private var dismiss

    @State private var pendingPeer: DiscoveredPeer?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                statusBlock
                if connectivity.hosts.isEmpty {
                    emptyState
                } else {
                    List(connectivity.hosts) { host in
                        Button {
                            pendingPeer = host
                        } label: {
                            HStack {
                                Image(systemName: host.transport == .ble ? "bolt.horizontal.fill" : "wifi")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(host.displayName).font(.headline)
                                    Text(host.transport.displayName)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .padding(20)
            .navigationTitle("Join Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await connectivity.scan(displayName: settings.displayName)
            }
            .onDisappear { connectivity.disconnect() }
            .sheet(item: $pendingPeer) { peer in
                ConfirmCodeSheet(peer: peer) {
                    Task { await connectivity.connect(to: peer) }
                    pendingPeer = nil
                    dismiss()
                }
            }
        }
    }

    private var statusBlock: some View {
        HStack {
            ProgressView().scaleEffect(0.8)
            Text("Scanning for nearby BuddyPlay phones…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No hosts visible yet.")
                .font(.headline)
            Text("Make sure both phones are on the same Wi-Fi (or that one is hosting a Mobile Hotspot the other has joined).")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .padding(.vertical, 12)
    }
}

private struct ConfirmCodeSheet: View {
    let peer: DiscoveredPeer
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Confirm pairing")
                .font(.title2.bold())
            Text("Make sure you and \(peer.displayName) see the same code on both screens before tapping Confirm.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Spacer()
            Button("Confirm pair", action: onConfirm)
                .buttonStyle(.borderedProminent)
            Button("Cancel", role: .cancel) { dismiss() }
            Spacer()
        }
        .padding(20)
        .presentationDetents([.medium])
    }
}

extension DiscoveredPeer: Identifiable {}
