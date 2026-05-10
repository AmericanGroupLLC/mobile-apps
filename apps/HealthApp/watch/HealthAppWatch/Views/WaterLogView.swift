import SwiftUI
import WatchKit
import FitFusionCore

/// Custom water amount via Digital Crown
struct WaterLogView: View {
    @State private var ml: Double = 250
    @State private var status: String?
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "drop.fill").font(.title).foregroundStyle(.white)
                Text("Water").font(.headline).foregroundStyle(.white)

                Text("\(Int(ml)) ml")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .focusable(true)
                    .digitalCrownRotation($ml,
                                          from: 50, through: 1500, by: 50,
                                          sensitivity: .medium, isContinuous: false)

                Text("Use Digital Crown to adjust")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))

                Button {
                    Task { await logWater() }
                } label: {
                    HStack {
                        if busy { ProgressView().controlSize(.small).tint(.white) }
                        Text("Log Water").bold()
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                if let s = status {
                    Text(s).font(.caption2).foregroundStyle(.white)
                }
            }
            .padding(8)
        }
    }

    private func logWater() async {
        busy = true; status = nil
        defer { busy = false }
        do {
            _ = try await APIClient.shared.logMetric(type: "water", value: ml, unit: "ml")
            await HealthKitManager.shared.writeWater(ml: ml)
            WKInterfaceDevice.current().play(.success)
            status = "✓ Logged \(Int(ml)) ml"
        } catch {
            WKInterfaceDevice.current().play(.failure)
            status = "⚠ Failed"
        }
    }
}
