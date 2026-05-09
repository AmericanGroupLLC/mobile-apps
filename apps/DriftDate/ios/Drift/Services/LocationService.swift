import Foundation
import CoreLocation
import DriftCore

/// On-device location fuzzer — truncates to ZIP-3 / county / state BEFORE any
/// network call. The Edge Function is defence-in-depth only.
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<FuzzedLocation, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer  // coarse only
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Returns a `FuzzedLocation` (never the raw lat/lon).
    func currentFuzzed() async -> FuzzedLocation {
        await withCheckedContinuation { cont in
            self.continuation = cont
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            continuation?.resume(returning: .empty); continuation = nil; return
        }
        // Skeleton: real impl resolves ZIP-prefix from a baked-in polygon table.
        // For now we only emit `nil`s, which the UI handles gracefully.
        guard LocationFuzzer.validateCoordinate(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude) else {
            continuation?.resume(returning: .empty); continuation = nil; return
        }
        continuation?.resume(returning: .empty)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: .empty)
        continuation = nil
    }
}
