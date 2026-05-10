import SwiftUI
import WatchKit
import FitFusionCore

/// Quick-Log: 4 big buttons for the most common 5-second loggings
struct QuickLogView: View {
    @State private var status: String?
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Quick Log").font(.headline).foregroundStyle(.white)
                    .padding(.top, 4)

                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        QLButton(icon: "drop.fill", label: "+250 ml", color: .blue) {
                            await log(type: "water", value: 250, unit: "ml", haptic: .success)
                        }
                        QLButton(icon: "figure.walk", label: "+1k steps", color: .green) {
                            await log(type: "steps", value: 1000, unit: "steps", haptic: .click)
                        }
                    }
                    GridRow {
                        QLButton(icon: "heart.fill", label: "Mood +", color: .pink) {
                            await log(type: "mood", value: 1, unit: "delta", haptic: .success)
                        }
                        QLButton(icon: "bed.double.fill", label: "+1 hr", color: .purple) {
                            await log(type: "sleep_hrs", value: 1, unit: "hr", haptic: .success)
                        }
                    }
                }

                if busy {
                    ProgressView().tint(.white)
                }
                if let s = status {
                    Text(s).font(.caption2).foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(8)
        }
    }

    private func log(type: String, value: Double, unit: String, haptic: WKHapticType) async {
        busy = true; status = nil
        defer { busy = false }
        do {
            _ = try await APIClient.shared.logMetric(type: type, value: value, unit: unit)
            WKInterfaceDevice.current().play(haptic)
            status = "✓ Logged \(Int(value)) \(unit)"
        } catch let e as APIError {
            WKInterfaceDevice.current().play(.failure)
            status = "⚠ \(e.error)"
        } catch {
            WKInterfaceDevice.current().play(.failure)
            status = "⚠ \(error.localizedDescription)"
        }
    }
}

private struct QLButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () async -> Void

    var body: some View {
        Button { Task { await action() } } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2).bold()
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
}
