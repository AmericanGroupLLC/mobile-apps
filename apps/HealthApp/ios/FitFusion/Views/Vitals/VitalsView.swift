import SwiftUI
import FitFusionCore

/// Aggregated vitals dashboard. One scrollable surface that shows every
/// supported HealthKit metric, grouped by category, with honest disclaimers
/// for non-sensorable items (body water %, snoring, true non-invasive BP /
/// glucose).
struct VitalsView: View {
    @StateObject private var service = VitalsService.shared
    @State private var showBP = false
    @State private var showGlucose = false
    @State private var showBodyComp = false
    @State private var showBioAge = false

    private var s: VitalsSnapshot { service.snapshot }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    biologicalAgeCard
                    section("Cardiovascular", colors: [.red, .pink]) {
                        grid([
                            tile("Heart Rate", s.heartRate.map { "\(Int($0)) bpm" }, "heart.fill", .red),
                            tile("Resting HR", s.restingHR.map { "\(Int($0)) bpm" }, "bed.double.fill", .red),
                            tile("HRV (SDNN)", s.hrv.map { "\(Int($0)) ms" }, "waveform.path.ecg", .pink),
                            tile("VO\u{2082} Max", s.vo2Max.map { String(format: "%.1f", $0) }, "lungs.fill", .blue),
                            tile("SpO\u{2082}", s.spo2.map { String(format: "%.0f%%", $0 * 100) }, "circle.hexagongrid.fill", .indigo),
                            tile("ECG (7d)", "\(s.ecgCountWeek)", "waveform", .orange),
                            tile("Irregular Rhythm", "\(s.irregularRhythmCount)", "exclamationmark.heart.fill", .red),
                            tile("Resp Rate", s.respiratoryRate.map { String(format: "%.0f /min", $0) }, "lungs", .teal),
                        ])
                    }

                    section("Activity (today)", colors: [.green, .blue]) {
                        grid([
                            tile("Steps", "\(s.todaySteps)", "figure.walk", .green),
                            tile("Distance", String(format: "%.2f km", s.distanceKmToday), "location.fill", .green),
                            tile("Active kcal", s.activeKcalToday.map { "\(Int($0))" }, "flame.fill", .orange),
                            tile("Basal kcal", s.basalKcalToday.map { "\(Int($0))" }, "circle.dotted", .yellow),
                            tile("Exercise min", s.exerciseMinToday.map { "\(Int($0))" }, "figure.run", .green),
                            tile("Floors", s.flightsClimbed.map { "\(Int($0))" }, "stairs", .indigo),
                        ])
                    }

                    section("Sleep (last night)", colors: [.indigo, .purple]) {
                        grid([
                            tile("Total", s.lastNightSleepHrs.map { String(format: "%.1f h", $0) }, "moon.stars.fill", .purple),
                            tile("Deep", s.deepSleepHrs.map { String(format: "%.1f h", $0) }, "moon.zzz.fill", .indigo),
                            tile("REM", s.remSleepHrs.map { String(format: "%.1f h", $0) }, "eye.fill", .blue),
                            tile("Wrist Temp \u{0394}", s.wristTempDeltaC.map { String(format: "%+.1f \u{00b0}C", $0) }, "thermometer", .orange),
                        ])
                    }

                    section("Body composition", colors: [.purple, .pink], action: ("Log", { showBodyComp = true })) {
                        grid([
                            tile("Weight", s.weight.map { String(format: "%.1f kg", $0) }, "scalemass.fill", .purple),
                            tile("BMI", s.bmi.map { String(format: "%.1f", $0) }, "figure", .indigo),
                            tile("Body fat", s.bodyFatPct.map { String(format: "%.0f%%", $0 * 100) }, "drop.degreesign", .pink),
                            tile("Lean mass", s.leanMassKg.map { String(format: "%.1f kg", $0) }, "figure.strengthtraining.traditional", .orange),
                            disclaimerTile("Body water %", "Tap to log",
                                           "Not sensored on Apple Watch. Use a smart scale + Health app or log manually.",
                                           "drop.fill", .blue),
                        ])
                    }

                    section("Vitals (manual / sensor)", colors: [.red, .orange],
                            action: ("Log BP", { showBP = true })) {
                        grid([
                            tile("Systolic", s.systolicBP.map { "\(Int($0))" }, "heart.text.square.fill", .red),
                            tile("Diastolic", s.diastolicBP.map { "\(Int($0))" }, "heart.text.square", .red),
                            disclaimerTile("Glucose",
                                           s.glucoseMgDl.map { String(format: "%.0f mg/dL", $0) } ?? "Tap to log",
                                           "No non-invasive sensor exists yet. Manual / CGM only.",
                                           "syringe.fill", .pink),
                            tile("Body temp", s.bodyTempC.map { String(format: "%.1f \u{00b0}C", $0) }, "thermometer", .orange),
                        ])
                    }

                    section("Hydration & wellness", colors: [.cyan, .teal]) {
                        grid([
                            tile("Water (today)",
                                 s.dietaryWaterMlToday > 0 ? "\(Int(s.dietaryWaterMlToday)) ml" : "0 ml",
                                 "drop.fill", .cyan),
                            disclaimerTile("Hydration sensor",
                                           "Not available",
                                           "True hydration sensing is still experimental in research labs. We rely on water intake + activity heuristics.",
                                           "wave.3.right", .gray),
                            tile("Mindful min", nil, "brain.head.profile", .indigo),
                            tile("Mood", nil, "face.smiling.fill", .pink),
                        ])
                    }

                    section("Environmental & safety", colors: [.gray, .indigo]) {
                        grid([
                            tile("Noise", s.audioExposureDb.map { String(format: "%.0f dB", $0) }, "speaker.wave.3.fill", .gray),
                            tile("UV index", s.uvExposureIndex.map { String(format: "%.0f", $0) }, "sun.max.fill", .yellow),
                            tile("Handwash", "\(s.handwashCountToday)", "hand.wave.fill", .blue),
                            tile("Unsteady (7d)", "\(s.unsteadyEvents)", "figure.walk.motion", .orange),
                        ])
                    }
                }
                .padding()
            }
            .navigationTitle("Vitals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await service.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task { await service.refresh() }
            .refreshable { await service.refresh() }
            .sheet(isPresented: $showBP) {
                ManualEntrySheet(title: "Blood Pressure",
                                 fields: [.init(label: "Systolic", default: 120),
                                          .init(label: "Diastolic", default: 80)]) { values in
                    if values.count == 2 {
                        Task { await service.writeBloodPressure(systolic: values[0], diastolic: values[1]); await service.refresh() }
                    }
                }
            }
            .sheet(isPresented: $showGlucose) {
                ManualEntrySheet(title: "Blood Glucose (mg/dL)",
                                 fields: [.init(label: "mg/dL", default: 95)]) { values in
                    if let v = values.first {
                        Task { await service.writeGlucose(mgDl: v); await service.refresh() }
                    }
                }
            }
            .sheet(isPresented: $showBodyComp) {
                ManualEntrySheet(title: "Body Composition",
                                 fields: [.init(label: "Body fat %", default: 18),
                                          .init(label: "Lean mass (kg)", default: 60)]) { values in
                    Task {
                        await service.writeBodyComposition(
                            fatPct: values.first.map { $0 / 100 },
                            leanKg: values.count > 1 ? values[1] : nil
                        )
                        await service.refresh()
                    }
                }
            }
            .sheet(isPresented: $showBioAge) {
                BiologicalAgeView()
                    .environmentObject(service)
            }
        }
    }

    // MARK: - Bio age summary card

    private var biologicalAgeCard: some View {
        Button { showBioAge = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "hourglass.tophalf.filled")
                    .font(.title2.weight(.bold))
                    .padding(12)
                    .background(.indigo.opacity(0.2), in: Circle())
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Biological Age").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Tap to estimate your bio age vs your real age")
                        .font(.subheadline)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(LinearGradient(colors: [.indigo.opacity(0.18), .pink.opacity(0.12)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section + tiles

    @ViewBuilder
    private func section<Content: View>(_ title: String,
                                        colors: [Color],
                                        action: (label: String, run: () -> Void)? = nil,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LinearGradient(colors: colors,
                                                    startPoint: .leading, endPoint: .trailing))
                Spacer()
                if let action = action {
                    Button(action.label, action: action.run)
                        .font(.caption.bold()).foregroundStyle(.indigo)
                }
            }
            content()
        }
    }

    private func grid(_ tiles: [VitalTile]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(tiles) { $0 }
        }
    }

    private func tile(_ name: String, _ value: String?, _ icon: String, _ color: Color) -> VitalTile {
        VitalTile(id: name, name: name, value: value ?? "\u{2014}",
                  icon: icon, color: color, disclaimer: nil)
    }

    private func disclaimerTile(_ name: String, _ value: String,
                                _ disclaimer: String,
                                _ icon: String, _ color: Color) -> VitalTile {
        VitalTile(id: name, name: name, value: value,
                  icon: icon, color: color, disclaimer: disclaimer)
    }
}

private struct VitalTile: View, Identifiable {
    let id: String
    let name: String
    let value: String
    let icon: String
    let color: Color
    let disclaimer: String?

    @State private var showDisclaimer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
                if disclaimer != nil {
                    Button { showDisclaimer = true } label: {
                        Image(systemName: "info.circle").font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(value).font(.headline.weight(.bold))
                .foregroundStyle(value == "\u{2014}" || value == "Not available" || value.contains("Tap") ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(name).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .alert(name, isPresented: $showDisclaimer) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(disclaimer ?? "")
        }
    }
}

// MARK: - Manual entry sheet

private struct ManualEntrySheet: View {
    struct Field { let label: String; let `default`: Double }
    let title: String
    let fields: [Field]
    let onSave: ([Double]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var values: [Double] = []

    var body: some View {
        NavigationStack {
            Form {
                ForEach(Array(fields.enumerated()), id: \.offset) { i, field in
                    HStack {
                        Text(field.label)
                        Spacer()
                        TextField("0", value: Binding(
                            get: { values.indices.contains(i) ? values[i] : field.default },
                            set: { newValue in
                                while values.count <= i { values.append(0) }
                                values[i] = newValue
                            }
                        ), format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Pad missing values with their defaults so the closure
                        // always receives `fields.count` numbers.
                        var out = values
                        while out.count < fields.count {
                            out.append(fields[out.count].default)
                        }
                        onSave(out)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if values.isEmpty { values = fields.map(\.default) }
            }
        }
    }
}
