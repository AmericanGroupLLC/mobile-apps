import SwiftUI
import WatchKit
import FitFusionCore

/// Wrist-friendly "Log a set" sheet. Digital Crown drives reps; a second
/// crown-bound field drives weight. Save \u{2192} inserts a CloudKit-synced
/// `ExerciseLogEntity` so the iPhone sees the new PR / history immediately.
struct QuickExerciseLogView: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss
    @State private var reps: Double = 8
    @State private var weight: Double = 0
    @State private var saved = false
    @FocusState private var focus: Field?

    enum Field { case reps, weight }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(exercise.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                crownTile(title: "Reps",
                          value: $reps,
                          range: 0...50, step: 1,
                          field: .reps,
                          formatter: { "\(Int($0))" })

                crownTile(title: "Weight (kg)",
                          value: $weight,
                          range: 0...300, step: 2.5,
                          field: .weight,
                          formatter: { $0 == 0 ? "BW" : "\(format($0)) kg" })

                Button { save() } label: {
                    Label(saved ? "Saved" : "Save Set",
                          systemImage: saved ? "checkmark.seal.fill" : "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity).font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(saved ? .green : .orange)
                .disabled(saved || reps <= 0)
            }
            .padding(8)
        }
        .containerBackground(.green.gradient, for: .navigation)
        .onAppear { focus = .reps }
    }

    private func crownTile(title: String,
                           value: Binding<Double>,
                           range: ClosedRange<Double>,
                           step: Double,
                           field: Field,
                           formatter: @escaping (Double) -> String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
            Text(formatter(value.wrappedValue))
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .focusable()
                .focused($focus, equals: field)
                .digitalCrownRotation(value, from: range.lowerBound, through: range.upperBound,
                                      by: step, sensitivity: .medium,
                                      isContinuous: false, isHapticFeedbackEnabled: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(focus == field ? 0.22 : 0.12),
                    in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture { focus = field }
    }

    private func save() {
        let set = CloudStore.LoggedSet(reps: Int(reps), weight: weight)
        _ = CloudStore.shared.addExerciseLog(exerciseId: exercise.id, sets: [set])
        WKInterfaceDevice.current().play(.success)
        saved = true
        // Auto-dismiss after a brief confirmation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
