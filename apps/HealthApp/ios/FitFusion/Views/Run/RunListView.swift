import SwiftUI
import FitFusionCore

struct RunListView: View {
    @EnvironmentObject var hk: iOSHealthKitManager
    @State private var runs: [iOSHealthKitManager.RunSummary] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        List {
            if loading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let e = error {
                Text(e).foregroundStyle(.red)
            } else if runs.isEmpty {
                ContentUnavailableView(
                    "No runs yet",
                    systemImage: "figure.run",
                    description: Text("Start a run on your Apple Watch and it'll show up here with route + pace charts.")
                )
            } else {
                ForEach(runs) { run in
                    NavigationLink {
                        RunDetailView(run: run)
                    } label: {
                        RunRow(run: run)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            runs = try await hk.fetchRecentRuns(limit: 30)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct RunRow: View {
    let run: iOSHealthKitManager.RunSummary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(.green.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(run.startDate, style: .date).font(.subheadline).bold()
                Text("\(String(format: "%.2f km", run.distanceKm)) · \(formatDuration(run.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(formatPace(run.paceSecPerKm)).font(.callout).bold()
                Text("min/km").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}

func formatPace(_ secondsPerKm: Double) -> String {
    guard secondsPerKm.isFinite, secondsPerKm > 0 else { return "—" }
    let mins = Int(secondsPerKm) / 60
    let secs = Int(secondsPerKm) % 60
    return String(format: "%d:%02d", mins, secs)
}
