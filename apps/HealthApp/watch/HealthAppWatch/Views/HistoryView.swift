import SwiftUI
import FitFusionCore

/// Recent metrics list
struct HistoryView: View {
    @State private var metrics: [Metric] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Recent")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                if loading {
                    ProgressView().tint(.white)
                } else if let e = error {
                    Text(e).font(.caption2).foregroundStyle(.white)
                } else if metrics.isEmpty {
                    Text("No entries yet")
                        .font(.caption2).foregroundStyle(.white.opacity(0.8))
                } else {
                    ForEach(metrics.prefix(15)) { m in
                        HStack {
                            Image(systemName: icon(for: m.type))
                                .foregroundStyle(.white)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(m.type.capitalized)
                                    .font(.caption).bold()
                                Text(formatTime(m.recorded_at))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                            Text(format(m))
                                .font(.caption2).bold()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                Button {
                    Task { await load() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .padding(8)
        }
        .task { await load() }
    }

    private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            metrics = try await APIClient.shared.listMetrics(limit: 30)
        } catch {
            self.error = "Couldn't load"
        }
    }

    private func icon(for type: String) -> String {
        switch type {
        case "water":     return "drop.fill"
        case "weight":    return "scalemass.fill"
        case "steps":     return "figure.walk"
        case "mood":      return "face.smiling.fill"
        case "sleep_hrs": return "bed.double.fill"
        default:          return "circle.fill"
        }
    }

    private func format(_ m: Metric) -> String {
        let v = m.value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(m.value))
            : String(format: "%.1f", m.value)
        return "\(v)\(m.unit ?? "")"
    }

    private func formatTime(_ s: String) -> String {
        // backend gives "YYYY-MM-DD HH:MM:SS"
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        if let d = f.date(from: s) {
            let out = DateFormatter()
            out.dateFormat = "MMM d HH:mm"
            return out.string(from: d)
        }
        return s
    }
}
