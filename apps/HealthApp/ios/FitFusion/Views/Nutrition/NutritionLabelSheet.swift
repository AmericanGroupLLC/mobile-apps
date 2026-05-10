import SwiftUI
import PhotosUI
import FitFusionCore

/// Nutrition-label OCR sheet. Camera or library \u{2192} `NutritionLabelOCR`
/// (`VNRecognizeTextRequest`) \u{2192} editable form \u{2192} existing `logMeal(_:)` flow.
struct NutritionLabelSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onLog: (NutritionService.FoodItem) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var name: String = "Scanned Item"
    @State private var kcal: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var barcode: String?
    @State private var loading = false
    @State private var detectedRaw: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoArea
                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        Label("Pick Label Photo", systemImage: "doc.viewfinder")
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(colors: [.indigo, .purple],
                                                       startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .onChange(of: pickerItem) { _, newValue in
                        Task { await scan(item: newValue) }
                    }

                    form

                    Button {
                        let item = NutritionService.FoodItem(
                            name: name, kcal: kcal, protein: protein,
                            carbs: carbs, fat: fat, barcode: barcode
                        )
                        onLog(item)
                        dismiss()
                    } label: {
                        Text("Log Meal").bold()
                            .frame(maxWidth: .infinity).padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(kcal == 0 && protein == 0 && carbs == 0 && fat == 0)

                    if !detectedRaw.isEmpty {
                        DisclosureGroup("Raw OCR") {
                            Text(detectedRaw)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Nutrition Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private var photoArea: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.regularMaterial)
                    .frame(height: 220)
                    .overlay(Text("Pick a clear photo of the nutrition facts.").font(.footnote)
                                .foregroundStyle(.secondary))
            }
            if loading {
                ProgressView("Reading\u{2026}")
                    .padding(12)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }

    private var form: some View {
        VStack(spacing: 8) {
            TextField("Name", text: $name).textFieldStyle(.roundedBorder)
            row("Calories (kcal)", value: $kcal)
            row("Protein (g)", value: $protein)
            row("Carbs (g)", value: $carbs)
            row("Fat (g)", value: $fat)
            if let bc = barcode {
                Text("Detected barcode: \(bc)")
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func row(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            TextField("0", value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 90)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func scan(item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                self.image = ui
                self.loading = true
                let result = await NutritionLabelOCR.shared.parse(image: ui)
                self.loading = false
                self.detectedRaw = result.rawText
                if let v = result.kcal { kcal = v }
                if let v = result.proteinG { protein = v }
                if let v = result.carbsG { carbs = v }
                if let v = result.fatG { fat = v }
                if let bc = result.detectedBarcode {
                    barcode = bc
                    // Resolve to a canonical name when possible.
                    if let item = try? await NutritionService.shared.lookup(barcode: bc) {
                        name = item.name
                        kcal = max(kcal, item.kcal)
                        protein = max(protein, item.protein)
                        carbs = max(carbs, item.carbs)
                        fat = max(fat, item.fat)
                    }
                }
            }
        } catch {
            loading = false
        }
    }
}
