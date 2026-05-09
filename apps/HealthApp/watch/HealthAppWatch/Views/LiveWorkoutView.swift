import SwiftUI
import HealthKit
import FitFusionCore

struct LiveWorkoutView: View {
    @StateObject private var controller = WorkoutController.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Workout").font(.headline).foregroundStyle(.white)

                if controller.isRunning {
                    metricsCard
                    HStack(spacing: 6) {
                        Button("Pause") { controller.pause() }
                            .buttonStyle(.bordered).tint(.yellow)
                        Button(role: .destructive) {
                            Task { await controller.end() }
                        } label: { Text("End") }
                        .buttonStyle(.borderedProminent).tint(.red)
                    }
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 38)).foregroundStyle(.white)
                    Text("Start a strength session").font(.caption)
                        .foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center)

                    Button {
                        controller.start(activityType: .traditionalStrengthTraining,
                                         location: .indoor)
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.orange)

                    if let err = controller.lastError {
                        Text(err).font(.caption2).foregroundStyle(.red)
                    }
                }
            }
            .padding(8)
        }
        .containerBackground(.orange.gradient, for: .tabView)
        // Always-on display while training
        .scenePadding(.horizontal)
    }

    private var metricsCard: some View {
        VStack(spacing: 6) {
            Text(format(controller.elapsedSeconds))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            HStack {
                metricTile(value: "\(Int(controller.heartRate))",
                           label: "BPM", color: .pink, icon: "heart.fill")
                metricTile(value: "\(Int(controller.activeCalories))",
                           label: "kcal", color: .red, icon: "flame.fill")
            }
        }
    }

    private func metricTile(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 1) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.callout).bold().foregroundStyle(.white)
            Text(label).font(.system(size: 9)).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private func format(_ s: TimeInterval) -> String {
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
