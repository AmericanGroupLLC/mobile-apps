import SwiftUI
import FitFusionCore

/// "Real age vs Biological age" detail screen. Reads the live `VitalsSnapshot`
/// from `VitalsService` plus a small profile section (chronological age, sex,
/// optional smoker / heavy-alcohol toggles) and runs the on-device
/// `BiologicalAgeEngine`.
///
/// Result is presented as a side-by-side gauge plus a factor breakdown
/// (each input's individual contribution in years), with an honest "this is
/// a heuristic, not a medical assessment" footnote.
struct BiologicalAgeView: View {
    @EnvironmentObject var vitals: VitalsService
    @Environment(\.dismiss) private var dismiss

    @AppStorage("bioAge.chronological") private var chronologicalYears: Double = 30
    @AppStorage("bioAge.sex") private var sexRaw: String = BiologicalAgeEngine.Sex.male.rawValue
    @AppStorage("bioAge.smoker") private var smoker: Bool = false
    @AppStorage("bioAge.alcohol") private var heavyAlcohol: Bool = false

    @State private var result: BiologicalAgeEngine.Result?

    private var sex: BiologicalAgeEngine.Sex {
        BiologicalAgeEngine.Sex(rawValue: sexRaw) ?? .male
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileSection
                    if let r = result {
                        comparisonGauge(r)
                        verdict(r)
                        factorList(r)
                    }
                    disclaimer
                }
                .padding()
            }
            .navigationTitle("Biological Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Estimate") { recompute() }
                }
            }
            .task { recompute() }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your profile").font(.headline)

            HStack {
                Text("Chronological age").font(.subheadline)
                Spacer()
                Stepper("\(Int(chronologicalYears)) yr", value: $chronologicalYears, in: 13...100, step: 1)
            }

            Picker("Sex", selection: $sexRaw) {
                Text("Male").tag(BiologicalAgeEngine.Sex.male.rawValue)
                Text("Female").tag(BiologicalAgeEngine.Sex.female.rawValue)
                Text("Other").tag(BiologicalAgeEngine.Sex.other.rawValue)
            }
            .pickerStyle(.segmented)

            Toggle("Smoker", isOn: $smoker)
            Toggle("Heavy alcohol use", isOn: $heavyAlcohol)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func comparisonGauge(_ r: BiologicalAgeEngine.Result) -> some View {
        HStack(spacing: 16) {
            ageColumn(label: "Chronological",
                      years: r.chronologicalYears,
                      color: .secondary)
            Image(systemName: r.deltaYears < 0 ? "arrow.down.right" : "arrow.up.right")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(r.deltaYears < 0 ? .green : .orange)
            ageColumn(label: "Biological",
                      years: r.biologicalYears,
                      color: r.deltaYears < 0 ? .green : .orange)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func ageColumn(label: String, years: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary)
            Text("\(Int(years))")
                .font(.system(size: 60, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Text("years").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func verdict(_ r: BiologicalAgeEngine.Result) -> some View {
        VStack(spacing: 6) {
            Text(r.verdict).font(.subheadline.bold())
                .multilineTextAlignment(.center)
            Text(String(format: "Confidence: %.0f%%", r.confidence * 100))
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func factorList(_ r: BiologicalAgeEngine.Result) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contributing factors").font(.headline)
            if r.factors.isEmpty {
                Text("No vitals yet \u{2014} grant HealthKit access to fill these in.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(r.factors) { f in
                    HStack {
                        Image(systemName: icon(for: f.direction))
                            .foregroundStyle(color(for: f.direction))
                        VStack(alignment: .leading) {
                            Text(f.name).font(.subheadline.bold())
                            Text(f.value).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%+.1f yr", f.deltaYears))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(color(for: f.direction))
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var disclaimer: some View {
        Text("This is a heuristic estimate built from the metrics in your Apple Health profile. It is **not** a medical diagnosis and should not be used to make medical decisions. Talk to a clinician for any health concern.")
            .font(.caption2).foregroundStyle(.secondary)
            .padding()
    }

    // MARK: - Compute

    private func recompute() {
        let s = vitals.snapshot
        let inputs = BiologicalAgeEngine.Inputs(
            chronologicalYears: chronologicalYears,
            sex: sex,
            restingHR: s.restingHR,
            hrv: s.hrv,
            vo2Max: s.vo2Max,
            avgSleepHours: s.lastNightSleepHrs,
            bmi: s.bmi,
            bodyFatPct: s.bodyFatPct,
            systolicBP: s.systolicBP,
            diastolicBP: s.diastolicBP,
            weeklyExerciseMin: s.exerciseMinToday.map { $0 * 7 },
            stepsPerDay: Double(s.todaySteps),
            smoker: smoker,
            heavyAlcohol: heavyAlcohol
        )
        result = BiologicalAgeEngine.shared.estimate(inputs)
    }

    private func icon(for d: BiologicalAgeEngine.Factor.Direction) -> String {
        switch d {
        case .better:  return "arrow.down.right.circle.fill"
        case .neutral: return "circle"
        case .worse:   return "arrow.up.right.circle.fill"
        }
    }
    private func color(for d: BiologicalAgeEngine.Factor.Direction) -> Color {
        switch d {
        case .better:  return .green
        case .neutral: return .secondary
        case .worse:   return .orange
        }
    }
}
