import SwiftUI
import Charts
import FitFusionCore

struct RunDetailView: View {
    let run: iOSHealthKitManager.RunSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryRow
                RunMapView(coordinates: run.routeCoordinates)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                paceChart
            }
            .padding()
        }
        .navigationTitle(run.startDate.formatted(date: .abbreviated, time: .shortened))
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statTile(title: "Distance", value: String(format: "%.2f km", run.distanceKm))
            statTile(title: "Duration", value: formatDuration(run.duration))
            statTile(title: "Pace", value: formatPace(run.paceSecPerKm) + " /km")
        }
    }

    private var paceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pace by km").font(.headline)
            if run.paceByKm.isEmpty {
                Text("No split data available")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(Array(run.paceByKm.enumerated()), id: \.offset) { idx, pace in
                        BarMark(
                            x: .value("KM", "\(idx + 1)"),
                            y: .value("Pace (s/km)", pace)
                        )
                        .foregroundStyle(LinearGradient(colors: [.orange, .pink],
                                                        startPoint: .top, endPoint: .bottom))
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).bold()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
