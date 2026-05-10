import Foundation
import Combine
import BuddyCore

/// Wraps `BuddyCore.ConnectivityBridge` for SwiftUI consumption.
/// Owns the iOS-side `WifiTransport` + `BleTransport` adapters.
@MainActor
final class ConnectivityService: ObservableObject {

    @Published var state: ConnectivityBridge.State = .idle
    @Published var hosts: [DiscoveredPeer] = []
    @Published var lastError: String?

    private let bridge: ConnectivityBridge
    private let deviceIds: DeviceIdProvider

    init() {
        let wifi = WifiTransport()
        let ble  = BleTransport()
        self.bridge = ConnectivityBridge(wifi: wifi, ble: ble)
        self.deviceIds = DeviceIdProvider()

        bridge.onStateChanged = { [weak self] s in
            Task { @MainActor in self?.state = s }
        }
        bridge.onHostsChanged = { [weak self] h in
            Task { @MainActor in self?.hosts = h }
        }
    }

    var preference: ConnectivityBridge.Preference {
        get { bridge.preference }
        set { bridge.preference = newValue }
    }

    /// The local peer identity, generated once per device.
    func localPeer(displayName: String) -> Peer {
        Peer(
            id: deviceIds.deviceId(),
            displayName: displayName,
            platform: .ios,
            lastSeenAt: Date()
        )
    }

    func host(displayName: String) async {
        do {
            try await bridge.host(as: localPeer(displayName: displayName))
        } catch {
            lastError = error.localizedDescription
        }
    }

    func scan(displayName: String) async {
        do {
            try await bridge.scan(as: localPeer(displayName: displayName))
        } catch {
            lastError = error.localizedDescription
        }
    }

    func connect(to peer: DiscoveredPeer) async {
        do {
            try await bridge.connect(to: peer)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func disconnect() {
        bridge.disconnect()
    }
}
