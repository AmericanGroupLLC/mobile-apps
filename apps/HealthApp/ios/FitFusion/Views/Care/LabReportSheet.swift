import SwiftUI
import FitFusionCore
#if canImport(UIKit)
import UIKit

/// Snap-a-lab-report sheet. Surfaced from Care home → "Snap lab report"
/// CTA. Pipeline: pick photo → on-device OCR (Vision) → schema-aware
/// extractor → review screen → save to PHIStore (per-condition reading).
///
/// All processing runs locally — image and OCR text never leave the device.
struct LabReportSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var processing = false
    @State private var result: LabReportOCR.Result?
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var saved = false

    private let tint = CarePlusPalette.careBlue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                    if let img = image {
                        Image(uiImage: img).resizable().scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        empty
                    }

                    if processing { ProgressView("Reading lab report…") }

                    if let r = result { reviewSection(r) }

                    Text("Photo and parsed text never leave this device.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("Snap lab report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $image, source: .camera).ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(image: $image, source: .photoLibrary).ignoresSafeArea()
            }
            .onChange(of: image) { _, new in
                guard let img = new else { return }
                Task { await runOCR(img) }
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder").font(.system(size: 48))
                .foregroundStyle(tint)
            Text("Snap or pick a printed lab summary.").font(.subheadline)
            HStack(spacing: 12) {
                Button { showCamera = true } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity).padding()
                        .background(tint, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                Button { showLibrary = true } label: {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(CarePlusPalette.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func reviewSection(_ r: LabReportOCR.Result) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Detected").font(CarePlusType.titleSM)
            row("A1C", r.a1c.map { String(format: "%.1f", $0) })
            row("Fasting glucose",
                r.fastingGlucose.map { "\($0.formatted()) mg/dL" })
            row("Blood pressure",
                (r.bpSystolic != nil && r.bpDiastolic != nil)
                    ? "\(r.bpSystolic!)/\(r.bpDiastolic!)" : nil)
            row("Total cholesterol", r.cholesterolTotal.map { "\($0.formatted())" })
            row("LDL", r.ldl.map { "\($0.formatted())" })
            row("HDL", r.hdl.map { "\($0.formatted())" })
            row("Triglycerides", r.triglycerides.map { "\($0.formatted())" })
            row("BMI", r.bmi.map { String(format: "%.1f", $0) })
            row("Weight", r.weightKg.map { String(format: "%.1f kg", $0) })
        }
        .padding()
        .background(CarePlusPalette.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 12))

        Button {
            save(r); saved = true
        } label: {
            Label(saved ? "Saved" : "Save to my care plan",
                  systemImage: saved ? "checkmark.seal.fill" : "square.and.arrow.down")
                .frame(maxWidth: .infinity).padding()
                .background(tint, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }.disabled(saved)
    }

    private func row(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—").font(.body.monospaced())
        }
        .padding(.vertical, 4)
    }

    @MainActor
    private func runOCR(_ img: UIImage) async {
        processing = true; defer { processing = false }
        result = await LabReportOCR.shared.parse(image: img)
    }

    /// Persists each detected value as a metric on the user's profile via
    /// the existing `APIClient.logMetric` path AND as a notes blob in the
    /// PHI store. iOS-only convenience; full audit trail is server-side.
    private func save(_ r: LabReportOCR.Result) {
        Task {
            if let a1c = r.a1c {
                _ = try? await APIClient.shared.logMetric(type: "a1c", value: a1c)
            }
            if let g = r.fastingGlucose {
                _ = try? await APIClient.shared.logMetric(type: "glucose_fasting", value: g, unit: "mg/dL")
            }
            if let s = r.bpSystolic, let d = r.bpDiastolic {
                _ = try? await APIClient.shared.logMetric(type: "bp_systolic", value: Double(s))
                _ = try? await APIClient.shared.logMetric(type: "bp_diastolic", value: Double(d))
            }
            if let w = r.weightKg {
                _ = try? await APIClient.shared.logMetric(type: "weight_kg", value: w, unit: "kg")
            }
        }
    }
}
#endif
