import SwiftUI
import CoreMotion
import HealthKit
import FitFusionCore

struct RunSessionView: View {
    @StateObject private var controller = WorkoutController.shared
    @StateObject private var route = RunRouteRecorder()
    @State private var pedometer = CMPedometer()
    @State private var pedometerDistance: Double = 0
    @State private var running = false
    @State private var error: String?

    private var liveDistance: Double {
        // Prefer GPS when active and producing samples, else fall back to pedometer.
        route.distanceMeters > 0 ? route.distanceMeters : pedometerDistance
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Run").font(.headline).foregroundStyle(.white)

                if running {
                    Text(String(format: "%.2f km", liveDistance / 1000))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Pace: " + format(route.paceSecPerKm) + " /km")
                        .font(.caption).foregroundStyle(.white.opacity(0.85))
                    Text("HR: \(Int(controller.heartRate)) bpm")
                        .font(.caption2).foregroundStyle(.white.opacity(0.85))
                    if !route.splits.isEmpty {
                        Text("Splits: " + route.splits.suffix(3).map(format).joined(separator: " · "))
                            .font(.caption2).foregroundStyle(.white.opacity(0.7))
                    }
                    if route.authorizationDenied {
                        Text("GPS denied — using pedometer only")
                            .font(.caption2).foregroundStyle(.yellow.opacity(0.9))
                    }

                    Button(role: .destructive) {
                        Task { await stop() }
                    } label: { Label("End Run", systemImage: "stop.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(.red)
                } else {
                    Image(systemName: "figure.run").font(.system(size: 38)).foregroundStyle(.white)
                    Button { start() } label: {
                        Label("Start Run", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.green)
                    if let e = error { Text(e).font(.caption2).foregroundStyle(.red) }
                }
            }
            .padding(8)
        }
        .containerBackground(.green.gradient, for: .tabView)
    }

    private func start() {
        running = true
        pedometerDistance = 0
        controller.start(activityType: .running, location: .outdoor)
        route.start()

        if CMPedometer.isDistanceAvailable() {
            pedometer.startUpdates(from: Date()) { data, _ in
                guard let data else { return }
                Task { @MainActor in
                    pedometerDistance = data.distance?.doubleValue ?? 0
                }
            }
        }
    }

    private func stop() async {
        pedometer.stopUpdates()
        running = false
        let workout = await controller.end()
        _ = await route.stop(attachingTo: workout)
    }

    private func format(_ s: TimeInterval) -> String {
        guard s.isFinite, s > 0 else { return "—:—" }
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
