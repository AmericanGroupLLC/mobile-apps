import SwiftUI
import FitFusionCore

struct NutritionView: View {
    @State private var data: MealListResponse?
    @State private var loading = false
    @State private var showScanner = false
    @State private var showSearch = false
    @State private var showMealPhoto = false
    @State private var showLabelOCR = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    totalsCard
                    actionRow
                    mealsList
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { barcode in
                    showScanner = false
                    Task { await handleBarcode(barcode) }
                }
            }
            .sheet(isPresented: $showSearch) {
                FoodSearchView { meal in
                    showSearch = false
                    Task { await logMeal(meal) }
                }
            }
            .sheet(isPresented: $showMealPhoto) {
                MealPhotoSheet { item in
                    showMealPhoto = false
                    Task { await logMeal(item) }
                }
            }
            .sheet(isPresented: $showLabelOCR) {
                NutritionLabelSheet { item in
                    showLabelOCR = false
                    Task { await logMeal(item) }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
            HStack(spacing: 12) {
                macroTile("Calories", value: data?.totals.kcal ?? 0, unit: "kcal", color: .orange)
                macroTile("Protein",  value: data?.totals.protein_g ?? 0, unit: "g", color: .pink)
                macroTile("Carbs",    value: data?.totals.carbs_g ?? 0, unit: "g", color: .yellow)
                macroTile("Fat",      value: data?.totals.fat_g ?? 0, unit: "g", color: .purple)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var actionRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { showScanner = true } label: {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [.orange, .pink],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                Button { showSearch = true } label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            HStack(spacing: 12) {
                Button { showMealPhoto = true } label: {
                    Label("Snap Meal", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [.indigo, .purple],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                Button { showLabelOCR = true } label: {
                    Label("Read Label", systemImage: "doc.viewfinder.fill")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    @ViewBuilder
    private var mealsList: some View {
        if let meals = data?.meals, !meals.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Logged today").font(.headline)
                ForEach(meals) { meal in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(meal.name).font(.subheadline).bold()
                            Text("\(Int(meal.kcal)) kcal · \(Int(meal.protein_g))P / \(Int(meal.carbs_g))C / \(Int(meal.fat_g))F")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(meal.recorded_at.suffix(8))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        } else if loading {
            ProgressView().frame(maxWidth: .infinity).padding()
        } else if let e = error {
            Text(e).font(.footnote).foregroundStyle(.red)
        } else {
            ContentUnavailableView(
                "Nothing logged yet",
                systemImage: "fork.knife",
                description: Text("Scan a barcode or search for a food to log your first meal.")
            )
            .padding(.top, 24)
        }
    }

    private func macroTile(_ title: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))").font(.title3).bold().foregroundStyle(color)
            Text("\(title) (\(unit))").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
    }

    // MARK: - Actions

    private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do { data = try await APIClient.shared.todayMeals() }
        catch let e as APIError { error = e.error }
        catch { self.error = error.localizedDescription }
    }

    private func handleBarcode(_ barcode: String) async {
        do {
            if let item = try await NutritionService.shared.lookup(barcode: barcode) {
                await logMeal(item)
            } else {
                error = "Food not found in Open Food Facts"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func logMeal(_ item: NutritionService.FoodItem) async {
        do {
            // 1) Backend
            _ = try await APIClient.shared.logMeal(
                name: item.name,
                kcal: item.kcal,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                barcode: item.barcode
            )
            // 2) HealthKit (HKCorrelation)
            await iOSHealthKitManager.shared.writeMeal(item)
            // 3) CloudKit-synced Core Data
            CloudStore.shared.addMeal(name: item.name, kcal: item.kcal,
                                      protein: item.protein, carbs: item.carbs, fat: item.fat,
                                      barcode: item.barcode)
            await load()
        } catch let e as APIError {
            error = e.error
        } catch {
            self.error = error.localizedDescription
        }
    }
}
