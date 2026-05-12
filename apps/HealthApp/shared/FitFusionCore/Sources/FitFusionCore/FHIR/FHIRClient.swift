import Foundation

/// Small typed FHIR client for the resources Care+ week 1 reads:
/// `Patient`, `Condition`, `MedicationStatement`, `AllergyIntolerance`,
/// `Observation`, `Encounter`, `Immunization`, `Appointment`.
///
/// The week 1 surface only renders counts + a Patient summary, so each
/// model is intentionally minimal — just enough to render the demo +
/// pass through a JSON blob for week-2 detail screens to expand later.
public final class FHIRClient {

    public let baseURL: String
    public let issuer: String

    public init(baseURL: String, issuer: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.issuer = issuer
    }

    public static func epicSandbox() -> FHIRClient {
        FHIRClient(baseURL: "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4",
                   issuer: EpicSandboxConfig.issuer)
    }

    // MARK: - Models (slim — Patient summary + Bundle counts)

    public struct Patient: Decodable {
        public let id: String?
        public let gender: String?
        public let birthDate: String?
        public let name: [HumanName]?

        public struct HumanName: Decodable {
            public let given: [String]?
            public let family: String?
            public let text: String?
        }

        public var displayName: String {
            if let text = name?.first?.text { return text }
            let given = name?.first?.given?.joined(separator: " ") ?? ""
            let family = name?.first?.family ?? ""
            let s = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
            return s.isEmpty ? "—" : s
        }
    }

    public struct Bundle: Decodable {
        public let total: Int?
        public let entry: [Entry]?
        public struct Entry: Decodable { public let resource: AnyCodable? }
    }

    /// Heterogeneous JSON pass-through. Week 2 detail screens decode these
    /// into typed Condition / Observation / etc. structs.
    public struct AnyCodable: Decodable {
        public let json: Any?
        public init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            self.json = try? c.decode([String: AnyCodable].self).mapValues { $0.json as Any }
        }
    }

    // MARK: - Reads

    public func patient(token: String, patientId: String) async throws -> Patient {
        try await get(token: token, path: "/Patient/\(patientId)", as: Patient.self)
    }

    /// Returns the `total` count from a paged Bundle. Care home renders
    /// these as "5 conditions", "12 observations" etc. for the demo.
    public func count(of resource: String, token: String, patientId: String) async throws -> Int {
        let bundle: Bundle = try await get(
            token: token,
            path: "/\(resource)?patient=\(patientId)&_summary=count",
            as: Bundle.self
        )
        return bundle.total ?? 0
    }

    /// Convenience: fetch counts for every resource Care+ v1 reads.
    public func summaryCounts(token: String, patientId: String) async throws -> [String: Int] {
        let resources = ["Condition", "MedicationStatement", "AllergyIntolerance",
                         "Observation", "Encounter", "Immunization", "Appointment"]
        var out: [String: Int] = [:]
        try await withThrowingTaskGroup(of: (String, Int).self) { group in
            for r in resources {
                group.addTask {
                    let n = try await self.count(of: r, token: token, patientId: patientId)
                    return (r, n)
                }
            }
            for try await (r, n) in group { out[r] = n }
        }
        return out
    }

    // MARK: - Plumbing

    private func get<T: Decodable>(token: String, path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NSError(domain: "FHIRClient", code: -1)
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/fhir+json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "FHIRClient",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: bodyStr])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
