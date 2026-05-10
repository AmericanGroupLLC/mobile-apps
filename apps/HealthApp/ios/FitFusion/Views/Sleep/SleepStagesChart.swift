import SwiftUI
import Charts
import FitFusionCore

struct SleepStagesChart: View {
    let snapshot: iOSHealthKitManager.SleepSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Night")
                .font(.headline)
            Text(String(format: "%.1f h total", snapshot.totalHours))
                .font(.subheadline).bold()

            if snapshot.stages.isEmpty {
                Text("Not enough data")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(snapshot.stages) { s in
                        BarMark(
                            x: .value("Start", s.start),
                            xEnd: .value("End", s.end),
                            y: .value("Stage", s.stage.label)
                        )
                        .foregroundStyle(s.stage.color)
                    }
                }
                .frame(height: 180)
            }

            HStack(spacing: 12) {
                stageTotal(.deep,  hours: snapshot.totalHours(for: .deep))
                stageTotal(.rem,   hours: snapshot.totalHours(for: .rem))
                stageTotal(.core,  hours: snapshot.totalHours(for: .core))
                stageTotal(.awake, hours: snapshot.totalHours(for: .awake))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func stageTotal(_ stage: iOSHealthKitManager.SleepStage, hours: Double) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1fh", hours))
                .font(.subheadline).bold()
                .foregroundStyle(stage.color)
            Text(stage.label)
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
