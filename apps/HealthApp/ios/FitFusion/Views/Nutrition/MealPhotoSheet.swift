import SwiftUI
import PhotosUI
import FitFusionCore

/// "Snap Meal" sheet \u{2014} lets the user pick a photo from the library or capture
/// one with the camera, runs `MealPhotoRecognizer` (Vision + Core ML) locally,
/// and presents the top-N candidate foods. The user picks one which then
/// flows through `NutritionService` (Open Food Facts) for ground-truth macros.
struct MealPhotoSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Called when the user accepts a final meal entry. Mirrors the existing
    /// `NutritionView.logMeal(_:)` callback shape.
    let onLog: (NutritionService.FoodItem) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var candidates: [MealPhotoRecognizer.Candidate] = []
    @State private var loading = false
    @State private var resolving: MealPhotoRecognizer.Candidate?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoArea
                    pickerRow
                    candidatesList
                }
                .padding()
            }
            .navigationTitle("Snap Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private var photoArea: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.regularMaterial)
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder").font(.largeTitle)
                            Text("Pick a photo of your meal").font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    )
            }
        }
    }

    private var pickerRow: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Label("Pick Photo", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(colors: [.orange, .pink],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .onChange(of: pickerItem) { _, newValue in
                Task { await load(item: newValue) }
            }
        }
    }

    @ViewBuilder
    private var candidatesList: some View {
        if loading {
            ProgressView("Recognizing\u{2026}").padding()
        } else if let e = error {
            Text(e).font(.footnote).foregroundStyle(.red)
        } else if !candidates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top guesses").font(.headline)
                ForEach(candidates) { c in
                    Button {
                        Task { await resolve(c) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(c.label.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .bold()
                                Text("\(Int(c.confidence * 100))% confidence")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if resolving?.id == c.id {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load(item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                self.image = ui
                self.candidates = []
                self.loading = true
                self.candidates = await MealPhotoRecognizer.shared.classify(image: ui)
                self.loading = false
                if candidates.isEmpty {
                    error = "No matches \u{2014} try the search button instead."
                }
            }
        } catch {
            self.error = error.localizedDescription
            self.loading = false
        }
    }

    private func resolve(_ candidate: MealPhotoRecognizer.Candidate) async {
        resolving = candidate
        defer { resolving = nil }
        do {
            // Try Open Food Facts using the model's label as a search term.
            let hits = try await NutritionService.shared.search(query: candidate.label)
            if let item = hits.first {
                onLog(item)
                dismiss()
            } else {
                // Fallback: log a zero-macro entry the user can edit later.
                let item = NutritionService.FoodItem(
                    name: candidate.label.replacingOccurrences(of: "_", with: " ").capitalized,
                    kcal: 0, protein: 0, carbs: 0, fat: 0, barcode: nil
                )
                onLog(item)
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
