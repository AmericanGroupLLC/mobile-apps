import SwiftUI
import FitFusionCore

/// Add a manual non-workout activity. Free-form name + duration + optional kcal.
struct AddActivityView: View {
    let onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind = "Walking"
    @State private var duration: Double = 30
    @State private var kcal: Double = 0
    @State private var notes = ""
    @State private var performedAt = Date()

    private let presets = ["Walking", "Cycling", "Yoga", "Gardening",
                            "Cleaning", "Stairs", "Swimming", "Stretching"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    Menu {
                        ForEach(presets, id: \.self) { p in
                            Button(p) { kind = p }
                        }
                    } label: {
                        HStack {
                            Text("Quick pick")
                            Spacer()
                            Text(kind).foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextField("Or type your own", text: $kind)
                        .textInputAutocapitalization(.words)
                }

                Section("Duration & calories") {
                    Stepper(value: $duration, in: 1...600, step: 1) {
                        Text("\(Int(duration)) min")
                    }
                    Stepper(value: $kcal, in: 0...3000, step: 5) {
                        Text("\(Int(kcal)) kcal")
                    }
                    DatePicker("When", selection: $performedAt)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        CloudStore.shared.addActivity(
                            kind: kind,
                            durationMin: duration,
                            kcalBurned: kcal,
                            notes: notes.isEmpty ? nil : notes,
                            performedAt: performedAt
                        )
                        onCreated()
                        dismiss()
                    }
                    .disabled(kind.isEmpty)
                }
            }
        }
    }
}
