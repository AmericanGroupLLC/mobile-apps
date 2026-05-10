import SwiftUI
import FitFusionCore
import Combine

/// Sets / reps / weight workout logger with a built-in rest timer. On save,
/// inserts an `ExerciseLogEntity` (CloudKit-synced) so PRs and history surface
/// in `ExerciseDetailView` next time.
struct WorkoutLoggerView: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss

    @State private var sets: [CloudStore.LoggedSet] = [.init(reps: 8, weight: 0)]
    @State private var notes: String = ""
    @State private var lastSession: [CloudStore.LoggedSet] = []
    @State private var showRest = false
    @State private var restSeconds = 90

    var body: some View {
        NavigationStack {
            Form {
                if !lastSession.isEmpty {
                    Section("Last session") {
                        ForEach(Array(lastSession.enumerated()), id: \.offset) { i, s in
                            HStack {
                                Text("Set \(i + 1)").foregroundStyle(.secondary)
                                Spacer()
                                Text("\(s.reps) \u{00d7} \(format(s.weight)) kg")
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                Section("Today") {
                    ForEach(Array(sets.enumerated()), id: \.offset) { i, _ in
                        HStack {
                            Text("Set \(i + 1)").foregroundStyle(.secondary)
                            Spacer()
                            Stepper(value: Binding(
                                get: { sets[i].reps },
                                set: { sets[i].reps = $0 }
                            ), in: 0...50) {
                                Text("\(sets[i].reps) reps")
                                    .frame(width: 80, alignment: .trailing)
                                    .monospacedDigit()
                            }
                            .labelsHidden()
                            TextField("kg", value: Binding(
                                get: { sets[i].weight },
                                set: { sets[i].weight = $0 }
                            ), format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                        }
                    }
                    .onDelete { sets.remove(atOffsets: $0) }

                    Button {
                        let last = sets.last ?? .init(reps: 8, weight: 0)
                        sets.append(.init(reps: last.reps, weight: last.weight))
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                    }
                }

                Section("Rest timer") {
                    Stepper("Rest: \(restSeconds) s",
                            value: $restSeconds, in: 15...300, step: 15)
                    Button {
                        showRest = true
                    } label: {
                        Label("Start rest timer", systemImage: "timer")
                    }
                }

                Section("Notes") {
                    TextField("How did it feel?", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let validSets = sets.filter { $0.reps > 0 }
                        guard !validSets.isEmpty else { dismiss(); return }
                        _ = CloudStore.shared.addExerciseLog(
                            exerciseId: exercise.id,
                            sets: validSets,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRest) {
                RestTimerSheet(seconds: restSeconds)
                    .presentationDetents([.medium])
            }
            .task { loadLastSession() }
        }
    }

    private func loadLastSession() {
        let logs = CloudStore.shared.fetchExerciseLogs(exerciseId: exercise.id, limit: 1)
        if let last = logs.first {
            lastSession = CloudStore.decodeSets(last)
            if !lastSession.isEmpty {
                // Pre-fill today's sets with the last session's shape.
                sets = lastSession
            }
        }
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

// MARK: - Rest timer sheet

struct RestTimerSheet: View {
    let seconds: Int
    @Environment(\.dismiss) private var dismiss
    @State private var remaining: Int
    @State private var timer: Timer?

    init(seconds: Int) {
        self.seconds = seconds
        self._remaining = State(initialValue: seconds)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Rest").font(.title3.bold()).foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(remaining) / CGFloat(max(seconds, 1)))
                    .stroke(LinearGradient(colors: [.orange, .pink],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: remaining)
                Text("\(remaining)")
                    .font(.system(size: 70, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 220, height: 220)

            HStack {
                Button(role: .cancel) {
                    timer?.invalidate()
                    dismiss()
                } label: {
                    Text("Skip")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    remaining = seconds
                    start()
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity).padding()
                        .background(.indigo.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear { start() }
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if remaining > 0 {
                remaining -= 1
            } else {
                t.invalidate()
            }
        }
    }
}
