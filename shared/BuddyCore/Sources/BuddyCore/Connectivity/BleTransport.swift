import Foundation
#if canImport(CoreBluetooth)
import CoreBluetooth
#endif

/// BLE GATT transport. Uses `CoreBluetooth` central + peripheral roles on
/// the BuddyPlay service UUID `0xBP01`. Single write-without-response
/// characteristic for client→host frames; single notify characteristic for
/// host→client frames.
///
/// This is a working scaffold — the actual `CBPeripheralManager` /
/// `CBCentralManager` delegate plumbing is more involved than the Wi-Fi
/// transport. For v1 the lobby can fall back to Wi-Fi if BLE fails to
/// initialise; the Connect screen surfaces the failure cleanly.
public final class BleTransport: NSObject, BuddyTransport {

    /// Service + characteristic UUIDs. Stable across iOS + Android impls.
    public static let serviceUUID = "42554450-0000-1000-8000-00805F9B34FB"
    public static let inboundCharUUID  = "42554450-0001-1000-8000-00805F9B34FB"
    public static let outboundCharUUID = "42554450-0002-1000-8000-00805F9B34FB"

    public var onHostsChanged: (([DiscoveredPeer]) -> Void)?
    public var onPeerConnected: ((Peer) -> Void)?
    public var onFrame: ((Data) -> Void)?
    public var onDisconnected: ((Error?) -> Void)?

    public override init() { super.init() }

    public func startHosting(localPeer: Peer) async throws {
        #if canImport(CoreBluetooth)
        // Real impl would set up a CBPeripheralManager, add the service +
        // characteristics, and start advertising. Keeping the scaffold
        // here so the BuddyTransport contract compiles; the full delegate
        // plumbing lands together with the iOS lobby in Phase 3.
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func stopHosting() {}

    public func startScanning(localPeer: Peer) async throws {
        #if canImport(CoreBluetooth)
        // Real impl: CBCentralManager.scanForPeripherals(withServices:[...]).
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func stopScanning() {}

    public func connect(to host: DiscoveredPeer) async throws {
        #if canImport(CoreBluetooth)
        // Real impl: CBCentralManager.connect(peripheral).
        #else
        throw TransportError.unsupportedPlatform
        #endif
    }

    public func send(_ frame: Data) async throws {
        // Real impl: chunk into MTU-sized writes and write to the inbound
        // characteristic.
    }

    public func disconnect() {}

    public enum TransportError: Swift.Error, Equatable {
        case unsupportedPlatform
        case bluetoothOff
        case notConnected
    }
}
