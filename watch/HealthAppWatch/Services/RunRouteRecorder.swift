import Foundation
import CoreLocation
import HealthKit

/// Wraps `CLLocationManager` (Best-for-navigation) + `HKWorkoutRouteBuilder` to capture
/// outdoor run GPS as both per-km splits (for live UI) and a final `HKWorkoutRoute`
/// (associated with the parent workout when finished).
///
/// Falls back gracefully when authorization is denied — the caller can keep using
/// `CMPedometer` distance and just won't get a polyline / splits.
@MainActor
final class RunRouteRecorder: NSObject, ObservableObject {

    // MARK: - Published state for the live Watch UI

    @Published var distanceMeters: Double = 0
    @Published var paceSecPerKm: Double = 0
    @Published var splits: [Double] = []   // sec/km per completed kilometer
    @Published var currentSpeed: Double = 0
    @Published var authorizationDenied = false
    @Published var isRecording = false

    // MARK: - Internals

    private let locationManager: CLLocationManager
    private let healthStore: HKHealthStore
    private var routeBuilder: HKWorkoutRouteBuilder?

    private var startedAt: Date?
    private var lastLocation: CLLocation?
    private var lastKmTime: Date?
    private var kmsCompleted: Int = 0

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.activityType = .fitness
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Lifecycle

    /// Begin recording. Requests `whenInUse` if needed.
    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationDenied = true
            return
        default: break
        }

        startedAt = Date()
        lastLocation = nil
        lastKmTime = startedAt
        kmsCompleted = 0
        distanceMeters = 0
        splits = []
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        isRecording = true
        locationManager.startUpdatingLocation()
    }

    /// Stop streaming and finalize the route, attaching it to the supplied workout.
    /// Returns the final `HKWorkoutRoute` (nil on failure).
    @discardableResult
    func stop(attachingTo workout: HKWorkout?) async -> HKWorkoutRoute? {
        locationManager.stopUpdatingLocation()
        isRecording = false
        guard let builder = routeBuilder else { return nil }
        defer { routeBuilder = nil }
        guard let workout else { return nil }
        do {
            return try await builder.finishRoute(with: workout, metadata: nil)
        } catch {
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension RunRouteRecorder: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .denied, .restricted:
                self.authorizationDenied = true
            default:
                self.authorizationDenied = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        // Filter out implausible low-accuracy readings that watchOS sometimes emits.
        let filtered = locations.filter { $0.horizontalAccuracy > 0 && $0.horizontalAccuracy < 50 }
        guard !filtered.isEmpty else { return }
        Task { @MainActor in
            self.consume(locations: filtered)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // Silently ignore transient errors — pedometer fallback keeps live UI usable.
    }

    @MainActor
    private func consume(locations: [CLLocation]) {
        guard let started = startedAt else { return }
        for loc in locations {
            currentSpeed = max(0, loc.speed)
            if let prev = lastLocation {
                let delta = loc.distance(from: prev)
                if delta.isFinite, delta < 200 {  // reject GPS jumps
                    distanceMeters += delta
                }
            }
            lastLocation = loc
        }
        // Hand the same batch to the HK route builder for the final HKWorkoutRoute.
        routeBuilder?.insertRouteData(locations) { _, _ in }

        let elapsed = Date().timeIntervalSince(started)
        if distanceMeters > 50 {
            paceSecPerKm = elapsed / (distanceMeters / 1000.0)
        }
        // Emit a per-kilometer split each time we cross a 1 km boundary.
        let totalKmFloor = Int(floor(distanceMeters / 1000.0))
        while totalKmFloor > kmsCompleted {
            kmsCompleted += 1
            let now = Date()
            if let last = lastKmTime {
                splits.append(now.timeIntervalSince(last))
            }
            lastKmTime = now
        }
    }
}
