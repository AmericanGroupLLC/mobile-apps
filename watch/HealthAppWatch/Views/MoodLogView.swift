import SwiftUI
import WatchKit
import FitFusionCore

/// 5-emoji mood picker (1-5 scale).
///
/// In MyHealth v1 the wrist still shows the lightning-fast 5-emoji UX, but on
/// submit we *also* emit an `HKStateOfMindSample`-equivalent payload to the
/// backend (and via WC to iPhone) so the iPhone dashboard's State of Mind
/// trend stays in sync.
struct MoodLogView: View {
    @State private var status: String?

    private let moods: [(emoji: String, label: String, value: Int, color: Color, valence: Double)] = [
        ("\u{1F61E}", "Awful",   1, .red,    -0.85),
        ("\u{1F641}", "Low",     2, .orange, -0.4),
        ("\u{1F610}", "Okay",    3, .yellow,  0.0),
        ("\u{1F642}", "Good",    4, .mint,    0.4),
        ("\u{1F604}", "Great",   5, .green,   0.85),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("How are you?").font(.headline).foregroundStyle(.white)
                Text("Tap a mood")
                    .font(.caption2).foregroundStyle(.white.opacity(0.8))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(moods, id: \.value) { m in
                        Button { Task { await log(m) } } label: {
                            VStack(spacing: 2) {
                                Text(m.emoji).font(.title)
                                Text(m.label).font(.caption2).bold()
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(m.color)
                    }
                }

                if let s = status {
                    Text(s).font(.caption2).foregroundStyle(.white)
                }
            }
            .padding(8)
        }
    }

    private func log(_ m: (emoji: String, label: String, value: Int, color: Color, valence: Double)) async {
        do {
            // Backend mood metric (existing).
            _ = try await APIClient.shared.logMetric(
                type: "mood", value: Double(m.value), unit: "1-5"
            )
            // State-of-mind metric so iPhone dashboard's StateOfMind trend stays in sync.
            _ = try? await APIClient.shared.logMetric(
                type: "state_of_mind_valence", value: m.valence, unit: "valence"
            )
            WKInterfaceDevice.current().play(.success)
            status = "\u{2713} \(m.emoji) \(m.label)"
        } catch {
            WKInterfaceDevice.current().play(.failure)
            status = "\u{26A0} Failed"
        }
    }
}
