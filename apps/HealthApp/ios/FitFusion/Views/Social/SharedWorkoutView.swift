import SwiftUI
#if canImport(GroupActivities)
import GroupActivities
#endif
import FitFusionCore

/// Receiver-side surface for a `SharedWorkoutActivity`. Lets each SharePlay
/// peer tap "I'm in" \u{2014} both devices then schedule the same `WorkoutTemplate`
/// at the same start time via `WorkoutScheduler`. The watch's
/// `WorkoutController` emits live HR / calories ticks to the active
/// `GroupSession.journal` so each friend can see the other's metrics.
struct SharedWorkoutView: View {
    let template: WorkoutTemplate

    @State private var imIn = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo)
            Text("Train together").font(.title2.bold())
            Text(template.name).font(.headline)
            Text("\(template.durationMin) min \u{00b7} \(template.category.label)")
                .font(.subheadline).foregroundStyle(.secondary)
            Button {
                Task { await join() }
            } label: {
                Label(imIn ? "Sent to Watch" : "I'm in",
                      systemImage: imIn ? "checkmark.seal.fill" : "play.fill")
                    .frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(colors: [.indigo, .purple],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .disabled(imIn)
        }
        .padding()
    }

    private func join() async {
        await WorkoutScheduler.shared.schedule(template: template, at: Date().addingTimeInterval(60))
        imIn = true
    }
}
