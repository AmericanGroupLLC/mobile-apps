import SwiftUI
import FitFusionCore

/// Post-workout RPE rating sheet. 1-10 slider with descriptive labels
/// (Borg CR-10 scale). Persists to PHIRPELogEntity via PHIStore so the
/// log is encrypted at rest. Mirrors the half-sheet pattern from
/// `Views/Sleep/StateOfMindLogger.swift`.
struct RPERatingSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Double = 6
    @State private var notes: String = ""
    @State private var saved = false

    private let tint = CarePlusPalette.workoutPink

    var body: some View {
        NavigationStack {
            VStack(spacing: CarePlusSpacing.lg) {
                header
                slider
                descriptor
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                Spacer()
                Button {
                    save()
                } label: {
                    Label(saved ? "Saved" : "Save RPE \(Int(rating))",
                          systemImage: saved ? "checkmark.seal.fill" : "square.and.arrow.down")
                        .frame(maxWidth: .infinity).padding()
                        .background(tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .disabled(saved)
            }
            .padding(CarePlusSpacing.lg)
            .navigationTitle("Rate this workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 36)).foregroundStyle(tint)
            Text("How hard did that feel?").font(.headline)
            Text("Borg CR-10 scale — useful for the adaptive plan.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var slider: some View {
        VStack(spacing: 8) {
            HStack {
                Text("1").font(.caption2).foregroundStyle(.secondary)
                Slider(value: $rating, in: 1...10, step: 1).tint(tint)
                Text("10").font(.caption2).foregroundStyle(.secondary)
            }
            Text("RPE \(Int(rating))").font(.title.bold()).foregroundStyle(tint)
        }
    }

    private var descriptor: some View {
        Text(label(for: Int(rating)))
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 8).padding(.horizontal, 14)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private func label(for r: Int) -> String {
        switch r {
        case 1: return "Nothing at all"
        case 2: return "Extremely light"
        case 3: return "Very light"
        case 4: return "Light"
        case 5: return "Moderate"
        case 6: return "Somewhat hard"
        case 7: return "Hard"
        case 8: return "Very hard"
        case 9: return "Extremely hard"
        case 10: return "Maximal"
        default: return ""
        }
    }

    private func save() {
        _ = PHIStore.shared.logRPE(
            rating: Int16(rating),
            workoutSessionId: nil,
            notes: notes.isEmpty ? nil : notes
        )
        saved = true
        // Small delay so the user sees the saved state, then dismiss.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
    }
}
