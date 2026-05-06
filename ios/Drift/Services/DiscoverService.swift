import Foundation
import DriftCore

/// Discovery REST queries scoped to the current layer.
final class DiscoverService {
    static let shared = DiscoverService()

    func candidates(in layer: Layer, viewer: Profile) async throws -> [Profile] {
        guard let client = SupabaseClient.shared else { return [] }
        var query: [String: String] = ["select": "*", "limit": "50"]
        switch layer {
        case .zip:    if let z = viewer.zipPrefix3  { query["zip_prefix3"] = "eq.\(z)" }
        case .county: if let c = viewer.countyFips  { query["county_fips"] = "eq.\(c)" }
        case .state:  if let s = viewer.stateCode   { query["state_code"]  = "eq.\(s)" }
        case .server: break
        }
        let rows: [Profile] = (try? await client.get("rest/v1/profiles", query: query)) ?? []
        return LayerScorer.sorted(candidates: rows.filter { $0.id != viewer.id }, viewer: viewer, layer: layer)
    }

    /// Insert a wave in the given layer; returns the inserted row.
    func wave(from viewer: Profile, to target: Profile, layer: Layer) async throws -> Wave {
        guard let client = SupabaseClient.shared else { throw DiscoverError.noClient }
        let wave = Wave(fromProfileId: viewer.id, toProfileId: target.id, layer: layer)
        let _: EmptyResponse = try await client.post("rest/v1/waves", body: wave)
        AnalyticsService.shared.track(.waveSent(layer: layer, surface: .app))
        return wave
    }

    enum DiscoverError: Error { case noClient }
}
