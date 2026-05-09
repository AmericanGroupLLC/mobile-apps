import Foundation

/// Wraps Open Food Facts (free, no key) for barcode and text-search lookups.
final class NutritionService {
    static let shared = NutritionService()
    private init() {}

    struct FoodItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let kcal: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let barcode: String?
    }

    func lookup(barcode: String) async throws -> FoodItem? {
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let status = raw?["status"] as? Int, status == 1,
              let product = raw?["product"] as? [String: Any] else {
            return nil
        }
        return parseProduct(product, barcode: barcode)
    }

    func search(query: String) async throws -> [FoodItem] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(q)&search_simple=1&action=process&json=1&page_size=20")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let products = raw?["products"] as? [[String: Any]] ?? []
        return products.compactMap { parseProduct($0, barcode: $0["code"] as? String) }
    }

    private func parseProduct(_ product: [String: Any], barcode: String?) -> FoodItem? {
        let name = (product["product_name"] as? String)
            ?? (product["generic_name"] as? String)
            ?? (product["brands"] as? String)
            ?? "Unknown food"
        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        let kcal = (nutriments["energy-kcal_100g"] as? Double)
            ?? (nutriments["energy-kcal_serving"] as? Double)
            ?? 0
        let protein = (nutriments["proteins_100g"] as? Double)
            ?? (nutriments["proteins_serving"] as? Double)
            ?? 0
        let carbs = (nutriments["carbohydrates_100g"] as? Double)
            ?? (nutriments["carbohydrates_serving"] as? Double)
            ?? 0
        let fat = (nutriments["fat_100g"] as? Double)
            ?? (nutriments["fat_serving"] as? Double)
            ?? 0

        guard kcal > 0 || protein > 0 || carbs > 0 || fat > 0 else { return nil }
        return FoodItem(name: name, kcal: kcal, protein: protein,
                        carbs: carbs, fat: fat, barcode: barcode)
    }
}
