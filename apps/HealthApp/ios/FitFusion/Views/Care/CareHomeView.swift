import SwiftUI
import FitFusionCore

/// Care tab home — top of the four-tab Care+ shell. Tile grid:
///  • Connect MyChart — CTA when not yet linked
///  • Insurance card  — CTA when not yet uploaded
///  • Care plan       — per-condition cards from HealthConditionsStore
///  • Doctors         — favorites + finder entry
///  • Annual reports  — coming soon
///  • Symptoms log    — coming soon
struct CareHomeView: View {
    @StateObject private var conditions = HealthConditionsStore.shared
    @State private var showHeaderProfile = false
    @State private var showHeaderBell = false
    @State private var myChartConnected = false  // wired by MyChartConnectView
    @State private var insuranceUploaded = false // wired by InsuranceCardSheet

    private let tint = CarePlusPalette.careBlue

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppHeader(tab: .care,
                          onProfile: { showHeaderProfile = true },
                          onBell: { showHeaderBell = true })

                ScrollView {
                    VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {

                        // ─── Quick connect tiles ───────────────────────
                        VStack(spacing: CarePlusSpacing.sm) {
                            NavigationLink {
                                MyChartConnectView(onConnected: { myChartConnected = true })
                            } label: {
                                ctaTile(symbol: "cross.case.fill",
                                        title: myChartConnected ? "MyChart connected"
                                                                  : "Connect MyChart",
                                        subtitle: myChartConnected
                                            ? "Tap to view your records."
                                            : "Read-only access via SMART-on-FHIR.",
                                        ctaText: myChartConnected ? nil : "Connect")
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                InsuranceCardSheet(onSaved: { insuranceUploaded = true })
                            } label: {
                                ctaTile(symbol: "creditcard.fill",
                                        title: insuranceUploaded
                                            ? "Insurance card on file"
                                            : "Add insurance card",
                                        subtitle: insuranceUploaded
                                            ? "Tap to update."
                                            : "Snap a photo — OCR runs on-device.",
                                        ctaText: insuranceUploaded ? nil : "Add")
                            }
                            .buttonStyle(.plain)

                            // ── New: snap a printed lab report ───────
                            NavigationLink {
                                LabReportSheet()
                            } label: {
                                ctaTile(symbol: "doc.text.viewfinder",
                                        title: "Snap lab report",
                                        subtitle: "On-device OCR pulls A1C, BP, lipids.",
                                        ctaText: "Snap")
                            }
                            .buttonStyle(.plain)
                        }

                        // ─── Care plan (per-condition) ─────────────────
                        sectionHeader("Care plan")
                        if conditions.hasAnyCondition {
                            ForEach(Array(conditions.conditions).sorted(by: { $0.label < $1.label }),
                                    id: \.self) { c in
                                if c != .none {
                                    let r = CarePlanReadings.reading(for: c)
                                    CarePlanCard(condition: c,
                                                 reading: r?.0,
                                                 readingHealthy: r?.1 ?? true)
                                }
                            }
                        } else {
                            emptyRow(
                                symbol: "stethoscope",
                                text: "Declare any conditions in Profile → Health profile to see a tailored care plan."
                            )
                        }

                        // ─── Quick links ───────────────────────────────
                        sectionHeader("Find help")
                        NavigationLink {
                            DoctorFinderView()
                        } label: {
                            tile(symbol: "stethoscope", title: "Doctors",
                                 subtitle: "Search by ZIP and specialty. Save favorites.")
                        }.buttonStyle(.plain)

                        NavigationLink {
                            ComingSoon(title: "Annual reports", symbol: "doc.text.magnifyingglass",
                                       tint: tint, etaWeek: 4)
                        } label: {
                            tile(symbol: "doc.text.magnifyingglass", title: "Annual reports",
                                 subtitle: "Yearly summary you can share with your doctor.")
                        }.buttonStyle(.plain)

                        NavigationLink {
                            ComingSoon(title: "Symptoms log", symbol: "thermometer.medium",
                                       tint: tint, etaWeek: 3)
                        } label: {
                            tile(symbol: "thermometer.medium", title: "Symptoms log",
                                 subtitle: "Track how you feel day-to-day.")
                        }.buttonStyle(.plain)
                    }
                    .padding(CarePlusSpacing.lg)
                }
            }
            .background(CarePlusPalette.surface.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showHeaderProfile) {
                NavigationStack { ProfileScreen() }
            }
            .sheet(isPresented: $showHeaderBell) {
                NewsDrawerSheet().presentationDetents([.medium, .large])
            }
        }
        .tint(tint)
    }

    // MARK: - Small components

    private func sectionHeader(_ s: String) -> some View {
        Text(s).font(CarePlusType.titleSM)
            .padding(.top, CarePlusSpacing.sm)
    }

    private func ctaTile(symbol: String, title: String, subtitle: String,
                         ctaText: String?) -> some View {
        HStack(spacing: CarePlusSpacing.md) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let cta = ctaText {
                Text(cta).font(.caption.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(tint, in: Capsule())
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CarePlusPalette.success)
            }
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private func tile(symbol: String, title: String, subtitle: String) -> some View {
        HStack(spacing: CarePlusSpacing.md) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private func conditionRow(_ c: HealthCondition) -> some View {
        HStack(spacing: CarePlusSpacing.md) {
            Image(systemName: c.symbol)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(c.label).font(.headline)
                Text(careTipFor(c)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(latestReadingFor(c))
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private func emptyRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: CarePlusSpacing.md) {
            Image(systemName: symbol).foregroundStyle(.secondary)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .padding(CarePlusSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    /// Tiny stub that maps a declared condition to a one-liner. Real care
    /// plan content (action items, articles, escalation paths) ships in
    /// week 3 alongside the symptoms log.
    private func careTipFor(_ c: HealthCondition) -> String {
        switch c {
        case .hypertension:     return "Aim for < 130/80 mmHg. Limit sodium."
        case .lowBloodPressure: return "Stay hydrated. Avoid sudden standing."
        case .heartCondition:   return "Keep workouts under your prescribed HR cap."
        case .diabetesT1, .diabetesT2:
            return "Pre/post-meal glucose check. Carb count."
        case .asthma:           return "Carry inhaler. Watch AQI."
        case .obesity:          return "Steady cardio + 0.5 kg/week deficit."
        default:                return "Tap to see condition-specific guidance."
        }
    }

    /// Placeholder for the per-condition latest reading. Wired to HealthKit
    /// in week 2 (BP, glucose, SpO2 reads via `HKHealthStore.statisticsQuery`).
    private func latestReadingFor(_ c: HealthCondition) -> String {
        switch c {
        case .hypertension, .lowBloodPressure: return "—/—"
        case .diabetesT1, .diabetesT2:         return "— mg/dL"
        case .heartCondition:                  return "— bpm"
        default:                               return ""
        }
    }
}
