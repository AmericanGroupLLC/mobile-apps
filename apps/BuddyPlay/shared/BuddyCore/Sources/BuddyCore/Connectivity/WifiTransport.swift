import Foundation
#if canImport(Network)
import Network
#endif

/// Wi-Fi transport using `Network.framework`'s `NWListener` (host) and
/// `NWConnection` (guest). Length-prefixed framing on a single TCP
/// connection.
public final class WifiTransport: BuddyTransport {
    public var onHostsChanged: (([DiscoveredPeer]) -> Void)?
    public var onPeerConnected: ((Peer) -> Void)?
    public var onFrame: ((Data) -> Void)?
    public var onDisconnected: ((Error?) -> Void)?

    public init() {}

    #if canImport(Network)
    private var listener: NWListener?
    private var connection: NWConnection?
    private var browser: NWBrowser?
    private var receiveBuffer = Data()
    private var localPeerId: UUID?
    #endif

    public func startHosting(localPeer: Peer) async throws {
        #if canImport(Network)
        localPeerId = localPeer.id
        let params = NWParameters.tcp
        let bonjour = NWListener.Service(name: localPeer.displayName, type: "_buddyplay._tcp")
        let l = try NWListener(using: params)
        l.service = bonjour
        l.newConnectionHandler = { [weak self] conn in self?.accept(conn) }
        l.start(queue: .main)
        listener = l
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func stopHosting() {
        #if canImport(Network)
        listener?.cancel()
        listener = nil
        #endif
    }

    public func startScanning(localPeer: Peer) async throws {
        #if canImport(Network)
        localPeerId = localPeer.id
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_buddyplay._tcp", domain: nil)
        let b = NWBrowser(for: descriptor, using: .tcp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            let peers: [DiscoveredPeer] = results.compactMap { result in
                if case .service(let name, _, _, _) = result.endpoint {
                    return DiscoveredPeer(
                        id: name, peerId: nil,
                        displayName: name, transport: .wifi
                    )
                }
                return nil
            }
            self.onHostsChanged?(peers)
        }
        b.start(queue: .main)
        browser = b
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func stopScanning() {
        #if canImport(Network)
        browser?.cancel()
        browser = nil
        #endif
    }

    public func connect(to host: DiscoveredPeer) async throws {
        #if canImport(Network)
        let endpoint = NWEndpoint.service(name: host.id, type: "_buddyplay._tcp", domain: "local.", interface: nil)
        let conn = NWConnection(to: endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.startReceiving(on: conn)
            case .failed(let err):
                self.onDisconnected?(err)
            case .cancelled:
                self.onDisconnected?(nil)
            default: break
            }
        }
        conn.start(queue: .main)
        connection = conn
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func send(_ frame: Data) async throws {
        #if canImport(Network)
        guard let conn = connection else { throw TransportError.notConnected }
        let framed = WireCodec.frame(frame)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Swift.Error>) in
            conn.send(content: framed, completion: .contentProcessed { err in
                if let err { cont.resume(throwing: err) } else { cont.resume() }
            })
        }
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func disconnect() {
        #if canImport(Network)
        connection?.cancel()
        connection = nil
        receiveBuffer.removeAll()
        #endif
    }

    #if canImport(Network)
    private func accept(_ conn: NWConnection) {
        connection = conn
        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                self.startReceiving(on: conn)
                // We don't know the remote Peer's id until they send us a
                // handshake frame (which the lobby layer will do).
            }
            if case .failed(let err) = state { self.onDisconnected?(err) }
        }
        conn.start(queue: .main)
    }

    private func startReceiving(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, err in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.receiveBuffer.append(data)
                while let (payload, consumed) = WireCodec.unframe(self.receiveBuffer) {
                    self.onFrame?(payload)
                    self.receiveBuffer.removeFirst(consumed)
                }
            }
            if isComplete { self.onDisconnected?(nil); return }
            if let err { self.onDisconnected?(err); return }
            self.startReceiving(on: conn)
        }
    }
    #endif

    public enum TransportError: Swift.Error, Equatable {
        case unsupportedPlatform
        case notConnected
    }
}
