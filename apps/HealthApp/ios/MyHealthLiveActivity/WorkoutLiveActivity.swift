import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity for an in-progress workout mirrored from the Apple Watch.
/// Renders Lock Screen banner + Dynamic Island compact / expanded / minimal
/// regions. Driven by `WorkoutActivityAttributes.ContentState` updates the
/// host app pushes from `WorkoutMirrorReceiver`.
struct WorkoutLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / banner UI.
            HStack(spacing: 14) {
                Image(systemName: context.state.activityIcon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.workoutName).font(.headline).foregroundStyle(.white)
                    Text(format(context.state.elapsedSeconds))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Label("\(Int(context.state.heartRate))", systemImage: "heart.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Label("\(Int(context.state.calories))", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding()
            .activityBackgroundTint(.orange)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(Int(context.state.heartRate)) bpm",
                          systemImage: "heart.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.pink)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label("\(Int(context.state.calories)) kcal",
                          systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.workoutName).font(.caption).bold()
                        Text(format(context.state.elapsedSeconds))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.distanceMeters > 0 {
                        Label(String(format: "%.2f km", context.state.distanceMeters / 1000),
                              systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.activityIcon)
            } compactTrailing: {
                Text(format(context.state.elapsedSeconds))
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
            } minimal: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
            }
        }
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
