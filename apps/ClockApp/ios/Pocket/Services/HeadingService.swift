import Foundation
import CoreLocation
import PocketCore

@MainActor
final class HeadingService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var magneticHeading: Double = 0
    @Published var trueHeading: Double = 0
    @Published var location: GeoCoordinate?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingHeading()
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.magneticHeading = HeadingMath.normalize(newHeading.magneticHeading)
            self.trueHeading     = newHeading.trueHeading >= 0
                ? HeadingMath.normalize(newHeading.trueHeading)
                : self.magneticHeading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            self.location = GeoCoordinate(latitude: last.coordinate.latitude,
                                          longitude: last.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
