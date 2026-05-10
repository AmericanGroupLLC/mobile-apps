import SwiftUI
import FitFusionCore

/// Searchable + filterable list of every exercise in the library. Different
/// from `AnatomyPickerView` (anatomy-first) \u{2014} this one is text-first.
struct ExerciseLibraryView: View {
    @State private var query: String = ""
    @State private var muscleFilter: MuscleGroup?
    @State private var equipmentFilter: Equipment?
    @State private var difficultyFilter: ExerciseDifficulty?
    @State private var includeStretches = true

    var body: some View {
        List {
            Section {
                filtersRow
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            ForEach(results) { exercise in
                NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                    ExerciseRow(exercise: exercise)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: "Search exercises")
        .navigationTitle("Library")
    }

    private var results: [Exercise] {
        var pool = ExerciseLibrary.exercises
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            pool = ExerciseLibrary.search(query)
        }
        return pool.filter { ex in
            if !includeStretches && ex.isStretch { return false }
            if let m = muscleFilter, !ex.primaryMuscles.contains(m), !ex.secondaryMuscles.contains(m) { return false }
            if let e = equipmentFilter, ex.equipment != e { return false }
            if let d = difficultyFilter, ex.difficulty != d { return false }
            return true
        }
    }

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All Muscles") { muscleFilter = nil }
                    ForEach(MuscleGroup.allCases) { m in
                        Button(m.label) { muscleFilter = m }
                    }
                } label: { chip(label: muscleFilter?.label ?? "Muscle", system: "figure.arms.open") }

                Menu {
                    Button("All Equipment") { equipmentFilter = nil }
                    ForEach(Equipment.allCases) { e in
                        Button(e.label) { equipmentFilter = e }
                    }
                } label: { chip(label: equipmentFilter?.label ?? "Equipment", system: "wrench.and.screwdriver") }

                Menu {
                    Button("Any Level") { difficultyFilter = nil }
                    ForEach(ExerciseDifficulty.allCases) { d in
                        Button(d.label) { difficultyFilter = d }
                    }
                } label: { chip(label: difficultyFilter?.label ?? "Level", system: "chart.bar.xaxis") }

                Toggle(isOn: $includeStretches) {
                    chip(label: includeStretches ? "Stretches \u{2713}" : "No stretches",
                         system: "figure.cooldown")
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func chip(label: String, system: String) -> some View {
        Label(label, systemImage: system)
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
    }
}
