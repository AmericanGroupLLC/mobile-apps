import SwiftUI
import FitFusionCore
import CoreData

/// Daily food diary. Top: today's macro rings + totals. Body: scrollable
/// history grouped by day, drilling into per-meal detail.
struct FoodDiaryView: View {
    @State private var meals: [NSManagedObject] = []
    @State private var customMeals: [NSManagedObject] = []
    @State private var showAdd = false
    @State private var showCustomBuilder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    todaySummary
                    customMealsCard
                    historyList
                }
                .padding()
            }
            .navigationTitle("Food Diary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showAdd = true } label: {
                            Label("Add meal", systemImage: "fork.knife")
                        }
                        Button { showCustomBuilder = true } label: {
                            Label("Custom meal builder", systemImage: "list.bullet.rectangle")
                        }
                    } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack { FoodSearchView() }
            }
            .sheet(isPresented: $showCustomBuilder) {
                CustomMealBuilderView { reload() }
            }
            .task { reload() }
            .refreshable { reload() }
        }
    }

    // MARK: - Sections

    private var todaySummary: some View {
        let today = meals.filter { isToday($0.value(forKey: "consumedAt") as? Date) }
        let kcal = today.reduce(0.0) { $0 + (($1.value(forKey: "kcal") as? Double) ?? 0) }
        let protein = today.reduce(0.0) { $0 + (($1.value(forKey: "protein") as? Double) ?? 0) }
        let carbs = today.reduce(0.0) { $0 + (($1.value(forKey: "carbs") as? Double) ?? 0) }
        let fat = today.reduce(0.0) { $0 + (($1.value(forKey: "fat") as? Double) ?? 0) }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Today").font(.headline)
            HStack(spacing: 12) {
                ringStat(label: "Calories", value: Int(kcal), unit: "kcal", color: .orange)
                ringStat(label: "Protein", value: Int(protein), unit: "g", color: .pink)
                ringStat(label: "Carbs", value: Int(carbs), unit: "g", color: .blue)
                ringStat(label: "Fat", value: Int(fat), unit: "g", color: .yellow)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var customMealsCard: some View {
        Group {
            if !customMeals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your custom meals").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(customMeals, id: \.objectID) { m in
                                let comps = CloudStore.decodeMealComponents(m)
                                Button {
                                    if let name = m.value(forKey: "name") as? String {
                                        // Quick log: sum the macros (placeholder, real
                                        // implementation can resolve grams to nutrition).
                                        CloudStore.shared.addMeal(
                                            name: name,
                                            kcal: 0, protein: 0, carbs: 0, fat: 0
                                        )
                                        reload()
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text((m.value(forKey: "name") as? String) ?? "Meal")
                                            .font(.caption.bold())
                                        Text("\(comps.count) items")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .padding(8)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History").font(.headline)
            let groups = Dictionary(grouping: meals) { meal -> Date in
                let date = (meal.value(forKey: "consumedAt") as? Date) ?? Date()
                return Calendar.current.startOfDay(for: date)
            }
            let sorted = groups.keys.sorted(by: >)

            if sorted.isEmpty {
                ContentUnavailableView(
                    "No meals logged yet",
                    systemImage: "fork.knife.circle",
                    description: Text("Tap + to add your first meal.")
                )
                .padding(.top, 20)
            } else {
                ForEach(sorted, id: \.self) { day in
                    Section {
                        Text(day.formatted(date: .complete, time: .omitted))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(groups[day] ?? [], id: \.objectID) { meal in
                            mealRow(meal)
                        }
                    }
                }
            }
        }
    }

    private func mealRow(_ meal: NSManagedObject) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading) {
                Text((meal.value(forKey: "name") as? String) ?? "Meal").font(.body.weight(.semibold))
                Text(time(meal.value(forKey: "consumedAt") as? Date))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int((meal.value(forKey: "kcal") as? Double) ?? 0)) kcal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func ringStat(label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func reload() {
        meals = CloudStore.shared.fetchMeals(daysBack: 14)
        customMeals = CloudStore.shared.fetchCustomMeals()
    }
    private func isToday(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        return Calendar.current.isDateInToday(d)
    }
    private func time(_ date: Date?) -> String {
        guard let d = date else { return "—" }
        return d.formatted(date: .omitted, time: .shortened)
    }
}
