import Foundation

/// `UserDefaults`-backed stable device UUID. Generated once on first
/// access; rotatable from Settings → Reset device ID.
public final class DeviceIdProvider {

    public static let defaultsKey = "buddyplay.deviceId"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func deviceId() -> UUID {
        if let str = defaults.string(forKey: Self.defaultsKey),
           let uuid = UUID(uuidString: str) {
            return uuid
        }
        let new = UUID()
        defaults.set(new.uuidString, forKey: Self.defaultsKey)
        return new
    }

    public func reset() -> UUID {
        let new = UUID()
        defaults.set(new.uuidString, forKey: Self.defaultsKey)
        return new
    }
}
