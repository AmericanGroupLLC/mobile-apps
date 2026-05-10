import Foundation
import CoreLocation
import PocketCore

@MainActor
final class WatchHeadingService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var magneticHeading: Double = 0
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
    }
    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingHeading()
    }
    func stop() { manager.stopUpdatingHeading() }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.magneticHeading = HeadingMath.normalize(newHeading.magneticHeading)
        }
    }
}
