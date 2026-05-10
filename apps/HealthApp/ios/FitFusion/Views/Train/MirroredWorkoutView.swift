import SwiftUI
import FitFusionCore

/// Full-screen iPhone surface that mirrors a workout currently running on the
/// paired Apple Watch via `HKWorkoutSession.startMirroringToCompanionDevice()`.
/// Driven by `WorkoutMirrorReceiver`.
struct MirroredWorkoutView: View {
    @ObservedObject var receiver: WorkoutMirrorReceiver

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            Text(format(receiver.elapsedSeconds))
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.bottom, 8)
            metricsGrid
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.orange, .pink, .purple],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: receiver.activityIcon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(.white.opacity(0.18), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Live from Apple Watch")
                    .font(.caption).bold()
                    .foregroundStyle(.white.opacity(0.9))
                Text("Mirrored Workout")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            metricTile(title: "Heart Rate",
                       value: "\(Int(receiver.heartRate))",
                       unit: "bpm",
                       icon: "heart.fill")
            metricTile(title: "Calories",
                       value: "\(Int(receiver.activeCalories))",
                       unit: "kcal",
                       icon: "flame.fill")
            metricTile(title: "Distance",
                       value: String(format: "%.2f", receiver.distanceMeters / 1000),
                       unit: "km",
                       icon: "location.fill")
        }
    }

    private func metricTile(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text("\(title) · \(unit)")
                .font(.caption2).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
    }

    private func format(_ s: TimeInterval) -> String {
        let total = Int(max(0, s))
        let h = total / 3600
        let m = (total % 3600) / 60
        let sec = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }
}
