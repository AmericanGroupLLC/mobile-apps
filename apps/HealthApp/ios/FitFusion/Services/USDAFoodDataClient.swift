import Foundation
import FitFusionCore

/// Thin client for the **USDA FoodData Central** public API. Free tier
/// requires a key from https://fdc.nal.usda.gov/api-key-signup.html.
///
/// **Falls back gracefully**: if no key is configured, every method returns
/// an empty list so callers (`MealPhotoSheet`, `FoodSearchView`) can keep
/// using the existing `NutritionService` (Open Food Facts) without behaviour
/// changes.
public final class USDAFoodDataClient {
    public static let shared = USDAFoodDataClient()
    private init() {}

    private static let apiKey: String? = {
        if let env = ProcessInfo.processInfo.environment["USDA_FDC_KEY"], !env.isEmpty {
            return env
        }
        if let stored = UserDefaults.standard.string(forKey: "usdaFdcKey"), !stored.isEmpty {
            return stored
        }
        return nil
    }()

    public struct FoodHit: Identifiable, Hashable {
        public let id: String
        public let description: String
        public let brandOwner: String?
        public let kcalPer100g: Double?
        public let proteinPer100g: Double?
        public let carbsPer100g: Double?
        public let fatPer100g: Double?
    }

    /// Search USDA FDC by free-text query. Returns up to 25 hits.
    public func search(query: String) async -> [FoodHit] {
        guard let apiKey = Self.apiKey, !query.isEmpty else { return [] }
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "25"),
        ]
        guard let url = components?.url else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
            return decoded.foods.map(Self.mapHit)
        } catch {
            return []
        }
    }

    // MARK: - Wire format

    private struct SearchResponse: Decodable {
        let foods: [FoodRow]
    }
    private struct FoodRow: Decodable {
        let fdcId: Int
        let description: String
        let brandOwner: String?
        let foodNutrients: [NutrientRow]?
    }
    private struct NutrientRow: Decodable {
        let nutrientName: String?
        let value: Double?
    }

    private static func mapHit(_ row: FoodRow) -> FoodHit {
        let nutrients = (row.foodNutrients ?? []).reduce(into: [String: Double]()) { acc, n in
            if let name = n.nutrientName, let v = n.value {
                acc[name.lowercased()] = v
            }
        }
        return FoodHit(
            id: String(row.fdcId),
            description: row.description,
            brandOwner: row.brandOwner,
            kcalPer100g: nutrients["energy"] ?? nutrients["energy (kcal)"],
            proteinPer100g: nutrients["protein"],
            carbsPer100g: nutrients["carbohydrate, by difference"]
                ?? nutrients["carbohydrates"],
            fatPer100g: nutrients["total lipid (fat)"] ?? nutrients["fat"]
        )
    }
}
