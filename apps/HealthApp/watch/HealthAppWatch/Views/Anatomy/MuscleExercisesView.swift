import SwiftUI
import FitFusionCore

/// All exercises that target a given `MuscleGroup`. Tap an exercise \u{2192}
/// `WatchExerciseDetailView`.
struct MuscleExercisesView: View {
    let muscle: MuscleGroup

    @State private var equipmentFilter: Equipment?
    @State private var includeStretches: Bool = true
    @State private var showFilterSheet = false

    private var results: [Exercise] {
        ExerciseLibrary.filter(muscle: muscle,
                               equipment: equipmentFilter,
                               includeStretches: includeStretches)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                // `Menu` is unavailable in watchOS; use a sheet-based picker
                // instead to expose the same filter options.
                Button {
                    showFilterSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(equipmentFilter?.label ?? "All equipment")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: Capsule())
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showFilterSheet) { filterSheet }

                ForEach(results) { exercise in
                    NavigationLink {
                        WatchExerciseDetailView(exercise: exercise)
                    } label: {
                        rowLabel(for: exercise)
                    }
                    .buttonStyle(.plain)
                }
                if results.isEmpty {
                    Text("No exercises match.")
                        .font(.caption2).foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 12)
                }
            }
            .padding(8)
        }
        .navigationTitle(muscle.label)
        .containerBackground(muscle.watchColor.gradient, for: .navigation)
    }

    private func rowLabel(for exercise: Exercise) -> some View {
        HStack(spacing: 8) {
            Image(systemName: exercise.equipment.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.18), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(exercise.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("\(exercise.equipment.label) \u{00b7} \(exercise.difficulty.label)")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Equipment") {
                    Button("All Equipment") {
                        equipmentFilter = nil
                        showFilterSheet = false
                    }
                    ForEach(Equipment.allCases) { e in
                        Button(e.label) {
                            equipmentFilter = e
                            showFilterSheet = false
                        }
                    }
                }
                Section {
                    Button(includeStretches ? "Hide stretches" : "Show stretches") {
                        includeStretches.toggle()
                        showFilterSheet = false
                    }
                }
            }
            .navigationTitle("Filter")
        }
    }
}
