import Foundation

/// The transport an active game session is using. Surfaced in the lobby so
/// the user knows whether they're on Wi-Fi, Hotspot, or BLE.
public enum Transport: String, Codable, Sendable {
    case wifi
    case hotspot
    case ble

    public var displayName: String {
        switch self {
        case .wifi:    return "Local Wi-Fi"
        case .hotspot: return "Mobile Hotspot"
        case .ble:     return "Bluetooth"
        }
    }

    /// Quality hint for the lobby. Real-time games (Racer) refuse `.ble`.
    public var supportsRealtime: Bool {
        switch self {
        case .wifi, .hotspot: return true
        case .ble:            return false
        }
    }
}
