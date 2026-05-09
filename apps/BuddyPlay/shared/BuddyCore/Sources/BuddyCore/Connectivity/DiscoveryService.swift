import Foundation
#if canImport(Network)
import Network
#endif

/// Bonjour-based discovery used by Wi-Fi transport. Kept as its own type
/// so the lobby UI can browse hosts independently of the transport's
/// connection state.
public final class DiscoveryService {
    public static let serviceType = "_buddyplay._tcp"

    public var onHostsChanged: (([DiscoveredPeer]) -> Void)?

    public init() {}

    #if canImport(Network)
    private var browser: NWBrowser?

    public func startBrowsing() {
        let descriptor = NWBrowser.Descriptor.bonjour(type: Self.serviceType, domain: nil)
        let b = NWBrowser(for: descriptor, using: .tcp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            let peers: [DiscoveredPeer] = results.compactMap { r in
                if case .service(let name, _, _, _) = r.endpoint {
                    return DiscoveredPeer(id: name, peerId: nil, displayName: name, transport: .wifi)
                }
                return nil
            }
            self.onHostsChanged?(peers)
        }
        b.start(queue: .main)
        browser = b
    }

    public func stopBrowsing() {
        browser?.cancel()
        browser = nil
    }
    #else
    public func startBrowsing() {}
    public func stopBrowsing() {}
    #endif
}
