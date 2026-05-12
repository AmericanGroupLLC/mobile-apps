import SwiftUI
import FitFusionCore

/// Renders the connected MyChart patient summary plus counts of every
/// resource type Care+ v1 reads. Tapping any count opens a placeholder
/// detail screen (week-2 typed renderers).
struct MyChartDataView: View {

    @State private var loading = true
    @State private var patient: FHIRClient.Patient?
    @State private var counts: [String: Int] = [:]
    @State private var error: String?

    private let tint = CarePlusPalette.careBlue
    private let issuer = EpicSandboxConfig.issuer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                if loading { ProgressView("Loading from MyChart…").padding(.top, 64) }
                else if let err = error {
                    errorView(err)
                } else {
                    patientCard
                    countsSection
                    Button(role: .destructive) {
                        disconnect()
                    } label: {
                        Label("Disconnect MyChart", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity).padding()
                            .background(CarePlusPalette.danger.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(CarePlusPalette.danger)
                    }
                }
            }
            .padding(CarePlusSpacing.lg)
        }
        .navigationTitle("MyChart records")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var patientCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.text.rectangle").foregroundStyle(tint)
                Text(patient?.displayName ?? "—").font(.title3.bold())
            }
            HStack(spacing: 16) {
                if let g = patient?.gender { Text("Sex: \(g.capitalized)").font(.caption) }
                if let b = patient?.birthDate { Text("DOB: \(b)").font(.caption) }
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: 14))
    }

    private var countsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resource counts").font(CarePlusType.titleSM)
            ForEach(["Condition", "MedicationStatement", "AllergyIntolerance",
                     "Observation", "Encounter", "Immunization", "Appointment"], id: \.self) { name in
                HStack {
                    Image(systemName: symbol(for: name)).foregroundStyle(tint).frame(width: 22)
                    Text(label(for: name))
                    Spacer()
                    Text("\(counts[name] ?? 0)").font(.headline).foregroundStyle(tint)
                }
                .padding()
                .background(CarePlusPalette.surfaceElevated,
                            in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func errorView(_ err: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle).foregroundStyle(CarePlusPalette.warning)
            Text("Could not load records").font(.headline)
            Text(err).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await load() } }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func load() async {
        loading = true; defer { loading = false }
        #if canImport(Security)
        guard let token = KeychainStore.shared.fhirAccessToken(issuer: issuer) else {
            error = "Not connected. Re-link MyChart from Care home."
            return
        }
        // Sandbox uses a known test patient ID until /Patient/$current resolves.
        // Real prod will read the `patient` claim from the token response.
        let patientId = UserDefaults.standard.string(forKey: "fhir.patientId") ?? "erXuFYUfucBZaryVksYEcMg3"

        let client = FHIRClient.epicSandbox()
        do {
            async let p = client.patient(token: token, patientId: patientId)
            async let c = client.summaryCounts(token: token, patientId: patientId)
            self.patient = try await p
            self.counts = try await c
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }
        #else
        self.error = "Keychain not available"
        #endif
    }

    private func disconnect() {
        #if canImport(Security)
        KeychainStore.shared.clearFhir(issuer: issuer)
        #endif
    }

    private func label(for r: String) -> String {
        switch r {
        case "Condition": return "Conditions"
        case "MedicationStatement": return "Medications"
        case "AllergyIntolerance": return "Allergies"
        case "Observation": return "Observations (vitals + labs)"
        case "Encounter": return "Encounters"
        case "Immunization": return "Immunizations"
        case "Appointment": return "Appointments"
        default: return r
        }
    }

    private func symbol(for r: String) -> String {
        switch r {
        case "Condition": return "list.bullet.clipboard"
        case "MedicationStatement": return "pills.fill"
        case "AllergyIntolerance": return "exclamationmark.triangle"
        case "Observation": return "waveform.path.ecg"
        case "Encounter": return "stethoscope"
        case "Immunization": return "syringe"
        case "Appointment": return "calendar.badge.clock"
        default: return "doc.text"
        }
    }
}
