import Foundation
import DriftCore

/// Reads + writes the current user's profile.
final class ProfileService {
    static let shared = ProfileService()

    private struct Empty: Encodable {}

    func fetchMine() async throws -> Profile? {
        guard let client = SupabaseClient.shared else { return nil }
        let rows: [Profile] = (try? await client.get("rest/v1/profiles", query: ["select": "*"])) ?? []
        return rows.first
    }

    func upsert(_ profile: Profile) async throws {
        guard let client = SupabaseClient.shared else { return }
        let _: EmptyResponse = try await client.post("rest/v1/profiles", body: profile)
    }
}
