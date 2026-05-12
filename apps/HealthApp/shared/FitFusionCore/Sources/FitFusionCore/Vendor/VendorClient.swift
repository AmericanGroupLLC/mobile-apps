import Foundation

/// Vendor (meal-delivery) network client. Wraps the backend
/// `/api/vendor/menu` endpoint. Real vendor partner identity is TBD —
/// week 1 ships a stub backend returning 6 sample vendors.
public final class VendorClient {

    public static let shared = VendorClient()
    private init() {}

    public struct Vendor: Codable, Identifiable, Hashable {
        public let id: String
        public let name: String
        public let cuisine: String?
        public let calories_per_meal_avg: Int?
        public let supports_conditions: [String]?
        public let logo_url: String?
        public let blurb: String?
    }

    public struct MenuResponse: Codable { public let vendors: [Vendor] }

    /// Fetch the vendor list filtered by the user's declared health
    /// conditions. Conditions are sent as a comma-separated `conditions`
    /// query param so the backend can filter.
    public func menu(conditions: [String]) async throws -> [Vendor] {
        let q = conditions.joined(separator: ",")
        let path = "/api/vendor/menu?conditions=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)"
        return try await APIClient.shared.sendRequest(path: path, as: MenuResponse.self).vendors
    }
}
