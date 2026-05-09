import SwiftUI
import FitFusionCore

/// Lightweight food search using Open Food Facts text search.
struct FoodSearchView: View {
    let onPick: (NutritionService.FoodItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [NutritionService.FoodItem] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                if loading {
                    ProgressView().padding()
                }
                if let e = error {
                    Text(e).foregroundStyle(.red).font(.footnote).padding()
                }
                List(results) { item in
                    Button { onPick(item) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.subheadline).bold()
                            Text("\(Int(item.kcal)) kcal · \(Int(item.protein))P / \(Int(item.carbs))C / \(Int(item.fat))F")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Search Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("Search Open Food Facts…", text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit { Task { await search() } }
            Button("Search") { Task { await search() } }
                .buttonStyle(.borderedProminent)
                .disabled(query.isEmpty)
        }
        .padding()
    }

    private func search() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            results = try await NutritionService.shared.search(query: query)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
