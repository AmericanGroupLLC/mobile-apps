import WidgetKit
import SwiftUI

/// iOS Lock Screen + Home Screen Readiness widget. Reads from the App Group
/// `group.com.fitfusion` shared `UserDefaults` (the same suite the watch
/// complication already consumes \u{2014} written by `HomeDashboardView.refresh()`).
struct ReadinessWidget: Widget {
    let kind = "MyHealthReadinessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessTimelineProvider()) { entry in
            ReadinessWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Readiness")
        .description("Today's MyHealth readiness on your Lock or Home Screen.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

struct ReadinessTimelineEntry: TimelineEntry {
    let date: Date
    let score: Int
    let suggestion: String
}

struct ReadinessTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadinessTimelineEntry {
        .init(date: Date(), score: 78, suggestion: "Solid day \u{2014} moderate effort")
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadinessTimelineEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessTimelineEntry>) -> Void) {
        let entry = currentEntry()
        let next = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> ReadinessTimelineEntry {
        let defaults = UserDefaults(suiteName: "group.com.fitfusion")
        let score = defaults?.integer(forKey: "readinessScore") ?? 0
        let suggestion = defaults?.string(forKey: "readinessSuggestion") ?? "Open MyHealth"
        return .init(date: Date(),
                     score: score == 0 ? 50 : score,
                     suggestion: suggestion)
    }
}

struct ReadinessWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReadinessTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(spacing: 6) {
                Text("Readiness").font(.caption).foregroundStyle(.secondary)
                Text("\(entry.score)")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text(entry.suggestion).font(.caption2).lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        case .systemMedium:
            HStack {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.score) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.score)").font(.title2).bold()
                }
                .frame(width: 80, height: 80)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Readiness").font(.caption).bold()
                    Text(entry.suggestion).font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding(8)
        case .accessoryCircular:
            Gauge(value: Double(entry.score), in: 0...100) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text("\(entry.score)").bold()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(scoreColor)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Image(systemName: "flame.fill").foregroundStyle(scoreColor)
                    Text("Readiness").font(.caption2).bold()
                    Spacer()
                    Text("\(entry.score)").font(.caption).bold().foregroundStyle(scoreColor)
                }
                Text(entry.suggestion).font(.caption2).lineLimit(2)
            }
        case .accessoryInline:
            Text("MyHealth \u{00b7} \(entry.score)")
        default:
            Text("\(entry.score)")
        }
    }

    private var scoreColor: Color {
        switch entry.score {
        case ..<40: return .red
        case ..<70: return .yellow
        default:    return .green
        }
    }
}
