import SwiftUI
import FitFusionCore

/// Build-your-own meal: name + a list of components (food + grams). Saves
/// to `CustomMealEntity` for one-tap re-logging from the Diary header.
struct CustomMealBuilderView: View {
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = "My meal"
    @State private var components: [CloudStore.MealComponent] = []
    @State private var newFood = ""
    @State private var newGrams: Double = 100

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Protein Bowl", text: $name)
                }
                Section("Add a component") {
                    TextField("Food (free-text)", text: $newFood)
                        .textInputAutocapitalization(.sentences)
                    Stepper(value: $newGrams, in: 0...1000, step: 5) {
                        Text("\(Int(newGrams)) g")
                    }
                    Button {
                        guard !newFood.isEmpty else { return }
                        components.append(.init(foodId: UUID().uuidString,
                                                name: newFood,
                                                grams: newGrams))
                        newFood = ""
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .disabled(newFood.isEmpty)
                }

                if !components.isEmpty {
                    Section("Components") {
                        ForEach(components, id: \.self) { c in
                            HStack {
                                Text(c.name)
                                Spacer()
                                Text("\(Int(c.grams)) g").foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { offsets in components.remove(atOffsets: offsets) }
                    }
                }
            }
            .navigationTitle("Custom meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        CloudStore.shared.addCustomMeal(name: name, components: components)
                        onSaved()
                        dismiss()
                    }
                    .disabled(name.isEmpty || components.isEmpty)
                }
            }
        }
    }
}
