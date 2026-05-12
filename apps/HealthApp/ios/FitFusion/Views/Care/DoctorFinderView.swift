import SwiftUI
import FitFusionCore

/// Doctor finder backed by the public NPPES Registry (free, no API key).
/// Backend `/api/doctors/search?zip=…&specialty=…` proxies the call so we
/// can audit the request and swap to Ribbon Health in v1.1 without
/// touching this screen.
struct DoctorFinderView: View {

    @State private var zip: String = ""
    @State private var specialty: String = ""
    @State private var loading = false
    @State private var results: [Provider] = []
    @State private var error: String?

    private let tint = CarePlusPalette.careBlue

    struct Provider: Codable, Identifiable, Hashable {
        let npi: String
        let name: String
        let specialty: String?
        let phone: String?
        let address_line: String?
        let zip: String?
        var id: String { npi }
    }

    private struct Response: Codable { let providers: [Provider] }

    var body: some View {
        VStack(alignment: .leading, spacing: CarePlusSpacing.md) {
            inputs
            if let err = error {
                Text(err).font(.caption).foregroundStyle(CarePlusPalette.danger)
            }
            if loading { ProgressView("Searching…") }

            List {
                ForEach(results) { p in
                    NavigationLink {
                        DoctorDetailView(provider: p)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name).font(.headline)
                            if let sp = p.specialty {
                                Text(sp).font(.caption).foregroundStyle(.secondary)
                            }
                            if let addr = p.address_line, !addr.isEmpty {
                                Text(addr).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding(CarePlusSpacing.lg)
        .navigationTitle("Find a doctor")
        .navigationBarTitleDisplayMode(.inline)
        .background(CarePlusPalette.surface.ignoresSafeArea())
    }

    private var inputs: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("ZIP code", text: $zip)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Specialty (optional)", text: $specialty)
                    .textFieldStyle(.roundedBorder)
            }
            Button {
                Task { await search() }
            } label: {
                Text("Search").bold()
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(tint, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .disabled(zip.count < 5)
        }
    }

    private func search() async {
        loading = true; defer { loading = false }
        var path = "/api/doctors/search?zip=\(zip)"
        if !specialty.isEmpty {
            let s = specialty.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? specialty
            path += "&specialty=\(s)"
        }
        do {
            let resp: Response = try await APIClient.shared.sendRequest(path: path, as: Response.self)
            self.results = resp.providers
            self.error = nil
        } catch {
            self.error = error.localizedDescription
            self.results = []
        }
    }
}
