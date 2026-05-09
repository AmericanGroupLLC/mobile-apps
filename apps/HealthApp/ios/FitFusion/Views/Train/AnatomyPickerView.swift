import SwiftUI
import FitFusionCore

/// MuscleWiki-style anatomy picker. Tap a muscle on the silhouette \u{2192} list
/// the exercises that target it (filtered by equipment + difficulty). Tap an
/// exercise to open `ExerciseDetailView` for instructions, form tips, and
/// the workout logger.
struct AnatomyPickerView: View {
    @State private var bodyView: BodyView = .front
    @State private var selectedMuscle: MuscleGroup?
    @State private var equipmentFilter: Equipment?
    @State private var difficultyFilter: ExerciseDifficulty?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MuscleSilhouetteView(view: $bodyView, selected: $selectedMuscle)
                    .frame(maxWidth: .infinity)

                filtersRow

                if let muscle = selectedMuscle {
                    let results = ExerciseLibrary.filter(
                        muscle: muscle,
                        equipment: equipmentFilter,
                        difficulty: difficultyFilter
                    )
                    Text("\(results.count) exercise\(results.count == 1 ? "" : "s") for \(muscle.label)")
                        .font(.headline)
                    if results.isEmpty {
                        ContentUnavailableView("No matches",
                                               systemImage: "magnifyingglass",
                                               description: Text("Try removing a filter."))
                            .padding(.top, 24)
                    } else {
                        ForEach(results) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    ContentUnavailableView("Tap a muscle",
                                           systemImage: "hand.tap.fill",
                                           description: Text("Pick a muscle on the body to see exercises that target it."))
                        .padding(.top, 24)
                }
            }
            .padding()
        }
        .navigationTitle("Anatomy")
    }

    private var filtersRow: some View {
        HStack {
            Menu {
                Button("All Equipment") { equipmentFilter = nil }
                ForEach(Equipment.allCases) { e in
                    Button(e.label) { equipmentFilter = e }
                }
            } label: {
                Label(equipmentFilter?.label ?? "Equipment", systemImage: "wrench.and.screwdriver")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
            }
            Menu {
                Button("Any Level") { difficultyFilter = nil }
                ForEach(ExerciseDifficulty.allCases) { d in
                    Button(d.label) { difficultyFilter = d }
                }
            } label: {
                Label(difficultyFilter?.label ?? "Level", systemImage: "chart.bar.xaxis")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
            }
            Spacer()
        }
    }
}

/// Compact list row used by both `AnatomyPickerView` and `ExerciseLibraryView`.
struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.equipment.systemImage)
                .font(.title3)
                .foregroundStyle(exercise.primaryMuscles.first?.color ?? .secondary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.subheadline.bold())
                Text("\(exercise.primaryMuscles.map(\.label).joined(separator: " \u{00b7} "))")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(exercise.equipment.label)
                    Text("\u{00b7}")
                    Text(exercise.difficulty.label)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
