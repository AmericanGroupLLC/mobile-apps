import SwiftUI
import FitFusionCore
import CoreData

/// Edit a single MealEntity. Sliders for quick macro adjustment + Save.
struct MealEditView: View {
    let meal: NSManagedObject
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kcal: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Name", text: $name)
                }
                Section("Macros") {
                    macroStepper("Calories", value: $kcal, range: 0...5000, step: 10, unit: "kcal")
                    macroStepper("Protein",  value: $protein, range: 0...300, step: 1, unit: "g")
                    macroStepper("Carbs",    value: $carbs, range: 0...500, step: 1, unit: "g")
                    macroStepper("Fat",      value: $fat, range: 0...300, step: 1, unit: "g")
                }
            }
            .navigationTitle("Edit meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        name = (meal.value(forKey: "name") as? String) ?? ""
        kcal = (meal.value(forKey: "kcal") as? Double) ?? 0
        protein = (meal.value(forKey: "protein") as? Double) ?? 0
        carbs = (meal.value(forKey: "carbs") as? Double) ?? 0
        fat = (meal.value(forKey: "fat") as? Double) ?? 0
    }

    private func save() {
        meal.setValue(name, forKey: "name")
        meal.setValue(kcal, forKey: "kcal")
        meal.setValue(protein, forKey: "protein")
        meal.setValue(carbs, forKey: "carbs")
        meal.setValue(fat, forKey: "fat")
        CloudStore.shared.save()
        onSaved()
        dismiss()
    }

    private func macroStepper(_ title: String, value: Binding<Double>,
                              range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        Stepper(
            value: value, in: range, step: step
        ) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
