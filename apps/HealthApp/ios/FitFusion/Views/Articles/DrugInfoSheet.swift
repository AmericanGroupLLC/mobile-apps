import SwiftUI
import FitFusionCore

/// OpenFDA drug-label lookup. Hits the existing backend `/api/health/drug`
/// route (no auth required, works for guest users too). Optional but
/// genuinely useful when adding a new medicine.
struct DrugInfoSheet: View {
    @State private var query = ""
    @State private var results: [DrugInfo] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                TextField("Drug name (e.g. ibuprofen)", text: $query)
                    .textInputAutocapitalization(.never)
                    .onSubmit { Task { await search() } }
                Button {
                    Task { await search() }
                } label: {
                    HStack {
                        if loading { ProgressView().controlSize(.small) }
                        Text("Search").bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.isEmpty)
            }

            if let error {
                Section { Text(error).foregroundStyle(.red) }
            }

            ForEach(results) { d in
                Section(d.brand ?? d.generic ?? "Drug") {
                    if let g = d.generic { LabeledContent("Generic", value: g) }
                    if let m = d.manufacturer { LabeledContent("Manufacturer", value: m) }
                    if let p = d.purpose { LabeledContent("Purpose", value: p).lineLimit(3) }
                    if let i = d.indications {
                        Text(i).font(.caption2).foregroundStyle(.secondary)
                    }
                    if let dosage = d.dosage {
                        Text("Dosage: \(dosage)").font(.caption2)
                    }
                    if let warnings = d.warnings {
                        Text(warnings).font(.caption2).foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Text("OpenFDA labels are produced by the U.S. Food and Drug Administration. They are not a substitute for medical advice from a clinician.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Drug info")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Networking

    struct DrugInfo: Identifiable, Decodable, Hashable {
        var id: String { (brand ?? "") + (generic ?? "") }
        let brand: String?
        let generic: String?
        let manufacturer: String?
        let purpose: String?
        let indications: String?
        let warnings: String?
        let dosage: String?
    }
    struct DrugResponse: Decodable {
        let query: String
        let results: [DrugInfo]
    }

    private func search() async {
        guard !query.isEmpty else { return }
        loading = true
        error = nil
        defer { loading = false }

        let base = APIConfig.baseURL
        var components = URLComponents(string: "\(base)/api/health/drug")
        components?.queryItems = [URLQueryItem(name: "name", value: query)]
        guard let url = components?.url else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(DrugResponse.self, from: data)
            results = decoded.results
        } catch {
            self.error = error.localizedDescription
        }
    }
}
