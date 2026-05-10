import SwiftUI
import WatchKit
import FitFusionCore

struct WeightLogView: View {
    @State private var kg: Double = 70.0
    @State private var status: String?
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "scalemass.fill").font(.title).foregroundStyle(.white)
                Text("Weight").font(.headline).foregroundStyle(.white)

                Text(String(format: "%.1f kg", kg))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .focusable(true)
                    .digitalCrownRotation($kg,
                                          from: 30, through: 250, by: 0.1,
                                          sensitivity: .high, isContinuous: false)

                Text("Crown to adjust")
                    .font(.caption2).foregroundStyle(.white.opacity(0.7))

                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        if busy { ProgressView().controlSize(.small).tint(.white) }
                        Text("Log Weight").bold()
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                if let s = status {
                    Text(s).font(.caption2).foregroundStyle(.white)
                }
            }
            .padding(8)
        }
    }

    private func save() async {
        busy = true; status = nil
        defer { busy = false }
        do {
            _ = try await APIClient.shared.logMetric(type: "weight", value: kg, unit: "kg")
            await HealthKitManager.shared.writeWeight(kg: kg)
            WKInterfaceDevice.current().play(.success)
            status = "✓ Logged \(String(format: "%.1f", kg)) kg"
        } catch {
            WKInterfaceDevice.current().play(.failure)
            status = "⚠ Failed"
        }
    }
}
