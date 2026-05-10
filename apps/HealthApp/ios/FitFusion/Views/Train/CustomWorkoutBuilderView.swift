import SwiftUI
import CoreData
import FitFusionCore

/// Build-your-own workout: drag-reorderable exercise list saved as a
/// CloudKit-synced `CustomWorkoutEntity`. Tap an exercise to open the logger.
struct CustomWorkoutBuilderView: View {
    @State private var name: String = "My Workout"
    @State private var picked: [Exercise] = []
    @State private var showPicker = false
    @State private var saved: [(NSManagedObject, [Exercise])] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Workout name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if picked.isEmpty {
                ContentUnavailableView(
                    "No exercises yet",
                    systemImage: "plus.square.dashed",
                    description: Text("Tap \u{201C}Add Exercise\u{201D} below to start building.")
                )
                .padding(.top, 16)
            } else {
                List {
                    ForEach(picked) { ex in
                        NavigationLink { ExerciseDetailView(exercise: ex) } label: {
                            ExerciseRow(exercise: ex)
                        }
                    }
                    .onMove { picked.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { picked.remove(atOffsets: $0) }
                }
                .listStyle(.plain)
            }

            HStack {
                Button { showPicker = true } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [.indigo, .purple],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .disabled(picked.isEmpty || name.isEmpty)
            }
            .padding(.horizontal)

            if !saved.isEmpty {
                Text("Saved").font(.headline).padding(.horizontal)
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(saved, id: \.0.objectID) { obj, ids in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text((obj.value(forKey: "name") as? String) ?? "Workout")
                                        .font(.subheadline.bold())
                                    Text(ids.map(\.name).prefix(3).joined(separator: " \u{00b7} "))
                                        .font(.caption2).foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text("\(ids.count) ex.")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.indigo)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Custom Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet { picked.append($0) }
        }
        .toolbar {
            EditButton()
        }
        .task { reloadSaved() }
    }

    private func save() {
        _ = CloudStore.shared.addCustomWorkout(name: name, exerciseIds: picked.map(\.id))
        picked = []
        name = "My Workout"
        reloadSaved()
    }

    private func reloadSaved() {
        let raw = CloudStore.shared.fetchCustomWorkouts()
        saved = raw.map { obj in
            let ids = CloudStore.decodeExerciseIds(obj)
            return (obj, ids.compactMap { ExerciseLibrary.byId($0) })
        }
    }
}

private struct ExercisePickerSheet: View {
    let onPick: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { ex in
                    Button {
                        onPick(ex); dismiss()
                    } label: {
                        ExerciseRow(exercise: ex)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search exercises")
            .navigationTitle("Pick Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filtered: [Exercise] {
        query.isEmpty ? ExerciseLibrary.exercises : ExerciseLibrary.search(query)
    }
}
