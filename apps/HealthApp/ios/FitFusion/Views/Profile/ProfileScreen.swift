import SwiftUI
import FitFusionCore

/// Care+ Profile screen reachable from the global header avatar on every
/// tab. Replaces the old `Views/More/HealthProfileView.swift` as the
/// primary "me" surface (HealthProfileView remains accessible inside this
/// screen as the dedicated medical conditions list).
///
/// Shows BMI auto-calc + a profile-completion percentage so users know
/// what's still missing before week 2's MyChart-merge backfills more data.
struct ProfileScreen: View {

    @StateObject private var hcStore = HealthConditionsStore.shared
    @Environment(\.dismiss) private var dismiss

    @AppStorage("profile.name") private var name: String = ""
    @AppStorage("profile.heightCm") private var heightCm: Double = 170
    @AppStorage("profile.weightKg") private var weightKg: Double = 65
    @AppStorage("profile.unitsImperial") private var unitsImperial: Bool = false

    private var bmi: Double {
        let h = heightCm / 100.0
        return h > 0 ? weightKg / (h * h) : 0
    }

    /// Crude completion estimate: 5 fields × 20% each.
    private var completionPercent: Int {
        var done = 0
        if !name.isEmpty { done += 1 }
        if heightCm > 0 { done += 1 }
        if weightKg > 0 { done += 1 }
        if hcStore.hasAnyCondition || hcStore.conditions == [.none] { done += 1 }
        if hcStore.lastDoctorReview != nil { done += 1 }
        return Int(Double(done) / 5.0 * 100.0)
    }

    var body: some View {
        Form {
            Section {
                completionCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Personal") {
                TextField("Name", text: $name)
                Stepper(value: $heightCm, in: 120...220, step: 1) {
                    Text("Height: \(Int(heightCm)) cm")
                }
                Stepper(value: $weightKg, in: 30...200, step: 0.5) {
                    Text(String(format: "Weight: %.1f kg", weightKg))
                }
                Toggle("Imperial units (ft / lb)", isOn: $unitsImperial)
            }

            Section("Connected sources") {
                connectedRow(symbol: "heart.text.square.fill",
                             label: "Apple Health",
                             status: .connected)
                connectedRow(symbol: "cross.case.fill",
                             label: "Epic MyChart",
                             status: KeychainStore.shared.fhirAccessToken(
                                issuer: EpicSandboxConfig.issuer
                             ) != nil ? .connected : .notConnected)
                connectedRow(symbol: "creditcard.fill",
                             label: "Insurance card",
                             status: PHIStore.shared.latestInsuranceCard() != nil
                                ? .connected : .notConnected)
                connectedRow(symbol: "pills.fill",
                             label: "Pharmacy",
                             status: .add)
            }

            Section("Body composition") {
                HStack {
                    Text("BMI")
                    Spacer()
                    Text(String(format: "%.1f", bmi)).foregroundStyle(.secondary)
                    Text(bmiLabel(bmi))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(bmiColor(bmi).opacity(0.18), in: Capsule())
                        .foregroundStyle(bmiColor(bmi))
                }
            }

            Section("Health profile") {
                NavigationLink("Conditions & medical history") { HealthProfileView() }
            }

            Section("Account") {
                NavigationLink("Settings") { SettingsView() }
            }

            Section {
                Button(role: .destructive) {
                    // Auth / wipe handled via environment elsewhere; this is
                    // just the placeholder hook so the screen renders the row.
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: CarePlusSpacing.sm) {
            HStack {
                Text("Profile completion").font(.subheadline)
                Spacer()
                Text("\(completionPercent)%").font(.headline)
                    .foregroundStyle(CarePlusPalette.careBlue)
            }
            ProgressView(value: Double(completionPercent), total: 100)
                .tint(CarePlusPalette.careBlue)
            Text("Complete your profile so MyChart imports merge cleanly.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
        .padding(.horizontal, CarePlusSpacing.lg)
        .padding(.vertical, CarePlusSpacing.sm)
    }

    private func bmiLabel(_ b: Double) -> String {
        switch b {
        case ..<18.5:  return "Under"
        case ..<25:    return "Normal"
        case ..<30:    return "Over"
        default:       return "Obese"
        }
    }

    private func bmiColor(_ b: Double) -> Color {
        switch b {
        case ..<18.5:  return CarePlusPalette.info
        case ..<25:    return CarePlusPalette.success
        case ..<30:    return CarePlusPalette.warning
        default:       return CarePlusPalette.danger
        }
    }

    // MARK: - Connected sources row

    private enum SourceStatus { case connected, notConnected, add }

    private func connectedRow(symbol: String, label: String,
                              status: SourceStatus) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(CarePlusPalette.careBlue).frame(width: 24)
            Text(label)
            Spacer()
            switch status {
            case .connected:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CarePlusPalette.success)
            case .notConnected:
                Text("Connect").font(.caption.weight(.semibold))
                    .foregroundStyle(CarePlusPalette.careBlue)
            case .add:
                Text("Add").font(.caption.weight(.semibold))
                    .foregroundStyle(CarePlusPalette.careBlue)
            }
        }
    }
}
