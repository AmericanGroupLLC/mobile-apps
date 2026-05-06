import Foundation

/// The transport-agnostic interface every connectivity adapter implements.
/// `WifiTransport` and `BleTransport` both conform; `ConnectivityBridge`
/// orchestrates them as a failover ladder.
public protocol BuddyTransport: AnyObject {
    /// Start advertising as a host. Calls `onPeerConnected` once a guest
    /// has connected, and `onFrame` for every inbound frame.
    func startHosting(localPeer: Peer) async throws
    func stopHosting()

    /// Start scanning for hosts. Surfaces them via `onHostsChanged`.
    func startScanning(localPeer: Peer) async throws
    func stopScanning()

    /// Connect to a discovered host.
    func connect(to host: DiscoveredPeer) async throws

    /// Send a length-prefixed frame.
    func send(_ frame: Data) async throws

    /// Disconnect cleanly.
    func disconnect()

    /// Live observers — set before calling `startHosting` / `startScanning`.
    var onHostsChanged: (([DiscoveredPeer]) -> Void)? { get set }
    var onPeerConnected: ((Peer) -> Void)? { get set }
    var onFrame: ((Data) -> Void)? { get set }
    var onDisconnected: ((Error?) -> Void)? { get set }
}

/// A peer that the local discovery layer has surfaced but not yet connected
/// to. `peerId` is parsed from the host's advertised metadata.
public struct DiscoveredPeer: Hashable, Sendable, Identifiable {
    public let id: String          // wire id (host:port for Wi-Fi, GATT addr for BLE)
    public let peerId: UUID?
    public let displayName: String
    public let transport: Transport

    public init(id: String, peerId: UUID?, displayName: String, transport: Transport) {
        self.id = id
        self.peerId = peerId
        self.displayName = displayName
        self.transport = transport
    }
}

/// State machine for the failover ladder. The UI's Connect screen listens
/// to `state` and renders accordingly.
public final class ConnectivityBridge {

    public enum State: Equatable, Sendable {
        case idle
        case advertising(via: Transport)
        case scanning(via: Transport)
        case connecting(to: DiscoveredPeer)
        case connected(peer: Peer, via: Transport)
        case failed(reason: String)
    }

    public enum Preference: String, Codable, Sendable {
        case auto, wifiOnly, bleOnly
    }

    public private(set) var state: State = .idle {
        didSet { onStateChanged?(state) }
    }
    public var preference: Preference = .auto

    public var onStateChanged: ((State) -> Void)?
    public var onHostsChanged: (([DiscoveredPeer]) -> Void)?
    public var onFrame: ((Data) -> Void)?

    private let wifi: BuddyTransport
    private let ble: BuddyTransport

    public init(wifi: BuddyTransport, ble: BuddyTransport) {
        self.wifi = wifi
        self.ble = ble
        wireObservers()
    }

    // MARK: - Public API

    public func host(as localPeer: Peer) async throws {
        switch preference {
        case .auto, .wifiOnly:
            do {
                try await wifi.startHosting(localPeer: localPeer)
                state = .advertising(via: .wifi)
                if preference == .auto {
                    // Also advertise on BLE so phones with no Wi-Fi can find us.
                    try? await ble.startHosting(localPeer: localPeer)
                }
                return
            } catch {
                if preference == .wifiOnly { state = .failed(reason: "Wi-Fi advertising failed"); throw error }
            }
            // Fall through to BLE.
            fallthrough
        case .bleOnly:
            try await ble.startHosting(localPeer: localPeer)
            state = .advertising(via: .ble)
        }
    }

    public func scan(as localPeer: Peer) async throws {
        switch preference {
        case .auto, .wifiOnly:
            try await wifi.startScanning(localPeer: localPeer)
            state = .scanning(via: .wifi)
            if preference == .auto {
                try? await ble.startScanning(localPeer: localPeer)
            }
        case .bleOnly:
            try await ble.startScanning(localPeer: localPeer)
            state = .scanning(via: .ble)
        }
    }

    public func connect(to host: DiscoveredPeer) async throws {
        state = .connecting(to: host)
        let t = host.transport == .ble ? ble : wifi
        try await t.connect(to: host)
    }

    public func send(_ frame: Data) async throws {
        switch state {
        case .connected(_, let t):
            let transport = t == .ble ? ble : wifi
            try await transport.send(frame)
        default:
            throw BridgeError.notConnected
        }
    }

    public func disconnect() {
        wifi.disconnect()
        ble.disconnect()
        state = .idle
    }

    // MARK: - Wiring

    private func wireObservers() {
        wifi.onHostsChanged = { [weak self] in self?.aggregateHosts(wifi: $0) }
        ble.onHostsChanged  = { [weak self] in self?.aggregateHosts(ble:  $0) }
        wifi.onFrame = { [weak self] in self?.onFrame?($0) }
        ble.onFrame  = { [weak self] in self?.onFrame?($0) }
        wifi.onPeerConnected = { [weak self] in self?.state = .connected(peer: $0, via: .wifi) }
        ble.onPeerConnected  = { [weak self] in self?.state = .connected(peer: $0, via: .ble) }
        wifi.onDisconnected = { [weak self] _ in self?.state = .idle }
        ble.onDisconnected  = { [weak self] _ in self?.state = .idle }
    }

    private var lastWifi: [DiscoveredPeer] = []
    private var lastBle:  [DiscoveredPeer] = []
    private func aggregateHosts(wifi: [DiscoveredPeer]) {
        lastWifi = wifi
        onHostsChanged?(lastWifi + lastBle)
    }
    private func aggregateHosts(ble: [DiscoveredPeer]) {
        lastBle = ble
        onHostsChanged?(lastWifi + lastBle)
    }

    public enum BridgeError: Swift.Error, Equatable {
        case notConnected
        case noTransportAvailable
    }
}
