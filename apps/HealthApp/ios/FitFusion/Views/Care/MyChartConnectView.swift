import SwiftUI
import FitFusionCore

/// MyChart connect screen — exact-scope-list surface.
///
/// 1. Lists every SMART scope we'll request in plain English.
/// 2. "Connect with MyChart" launches `ASWebAuthenticationSession` against
///    Epic's sandbox (real OAuth, sandbox login).
/// 3. On success: persist tokens to Keychain, navigate to `MyChartDataView`.
struct MyChartConnectView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var verifier = FHIROAuthClient.makeCodeVerifier()
    @State private var stateValue = FHIROAuthClient.makeState()
    @State private var isConnecting = false
    @State private var errorText: String?
    @State private var connectedPatientId: String?

    let onConnected: () -> Void

    private let tint = CarePlusPalette.careBlue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                header

                Group {
                    sectionTitle("What we'll read")
                    scopeRow(symbol: "person.text.rectangle", text: "Your patient profile")
                    scopeRow(symbol: "list.bullet.clipboard", text: "Conditions and problem list")
                    scopeRow(symbol: "pills.fill", text: "Active medications")
                    scopeRow(symbol: "exclamationmark.triangle", text: "Allergies and intolerances")
                    scopeRow(symbol: "waveform.path.ecg", text: "Vital sign and lab observations")
                    scopeRow(symbol: "calendar.badge.clock", text: "Past and upcoming appointments")
                    scopeRow(symbol: "syringe", text: "Immunizations")
                }

                Group {
                    sectionTitle("What we won't do")
                    bulletRow("Write back into your chart (read-only)")
                    bulletRow("Share your data with a third party")
                    bulletRow("Store data unencrypted on this device")
                    bulletRow("Survive after you tap \"Disconnect\" — we wipe tokens immediately")
                }

                Group {
                    sectionTitle("Sandbox login")
                    Text("This is the Epic public **sandbox**. No real PHI. Use any of:")
                        .font(.footnote).foregroundStyle(.secondary)
                    ForEach(EpicSandboxConfig.sandboxPatients, id: \.label) { p in
                        Text("• **\(p.label)** — \(p.login)").font(.caption)
                    }
                }

                if let err = errorText {
                    Text(err).font(.caption).foregroundStyle(CarePlusPalette.danger)
                }

                Button {
                    Task { await connect() }
                } label: {
                    HStack {
                        if isConnecting { ProgressView().tint(.white) }
                        Text(isConnecting ? "Connecting…" : "Connect with MyChart")
                            .bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
                .disabled(isConnecting)

                Text("By continuing you agree to MyHealth's HIPAA-grade handling of your medical data. Tokens are stored only in this device's Keychain and never leave it.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(CarePlusSpacing.lg)
        }
        .navigationTitle("Connect MyChart")
        .navigationBarTitleDisplayMode(.inline)
        .background(CarePlusPalette.surface.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 90, height: 90)
                Image(systemName: "cross.case.fill").font(.system(size: 38)).foregroundStyle(tint)
            }
            Text("SMART-on-FHIR").font(.subheadline).foregroundStyle(.secondary)
            Text("Bring your records into Care+").font(CarePlusType.title)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).font(CarePlusType.titleSM).padding(.top, 8)
    }

    private func scopeRow(symbol: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 24)
            Text(text).font(.subheadline)
            Spacer()
        }
    }

    private func bulletRow(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(CarePlusPalette.success)
            Text(s).font(.caption)
        }
    }

    @MainActor
    private func connect() async {
        #if canImport(AuthenticationServices)
        errorText = nil
        isConnecting = true
        defer { isConnecting = false }

        let client = FHIROAuthClient.epicSandbox
        verifier = FHIROAuthClient.makeCodeVerifier()
        stateValue = FHIROAuthClient.makeState()

        guard let url = client.authorizationURL(state: stateValue, codeVerifier: verifier) else {
            errorText = "Failed to build authorization URL"; return
        }
        do {
            let result = try await FHIROAuthSession.shared.authenticate(
                authorizationURL: url,
                callbackScheme: "myhealth",
                expectedState: stateValue
            )
            let token = try await client.exchangeCode(result.code, codeVerifier: verifier)
            client.persist(token: token)
            connectedPatientId = token.patient
            // Care+ PHI rule: the FHIR `patient` claim is a clinical
            // identifier and must stay on-device. Server's `mychart_issuer`
            // table only records that the user connected issuer X.
            PHIStore.shared.saveMyChartIssuer(
                issuer: client.config.issuer,
                displayName: "Epic MyChart",
                patientId: token.patient
            )
            UserDefaults.standard.set(token.patient, forKey: "fhir.patientId")
            onConnected()
            // Navigate forward via the parent navigation; for now dismiss this
            // sheet/stack and let CareHomeView render the connected state.
            dismiss()
        } catch FHIROAuthSession.SessionError.cancelled {
            errorText = "Connection cancelled."
        } catch {
            errorText = error.localizedDescription
        }
        #else
        errorText = "OAuth requires iOS."
        #endif
    }
}
