import SwiftUI
import FitFusionCore

struct MealDetailView: View {
    let meal: Meal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(meal.name).font(.title).bold()
                Text("Logged \(meal.recorded_at)")
                    .font(.caption).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    macro("Calories", value: meal.kcal, unit: "kcal", color: .orange)
                    macro("Protein",  value: meal.protein_g, unit: "g", color: .pink)
                    macro("Carbs",    value: meal.carbs_g, unit: "g", color: .yellow)
                    macro("Fat",      value: meal.fat_g, unit: "g", color: .purple)
                }

                if let bc = meal.barcode {
                    Label("Barcode: \(bc)", systemImage: "barcode")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Meal")
    }

    private func macro(_ title: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))").font(.title3).bold().foregroundStyle(color)
            Text("\(title) (\(unit))").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
