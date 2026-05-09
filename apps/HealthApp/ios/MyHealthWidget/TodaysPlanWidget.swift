import WidgetKit
import SwiftUI

/// "Today's Plan" widget \u{2014} surfaces the first scheduled workout from
/// `WorkoutPlanEntity` (CloudKit-synced via CloudStore). Reads a denormalized
/// summary string the iOS app writes to the App Group.
struct TodaysPlanWidget: Widget {
    let kind = "MyHealthTodaysPlanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaysPlanProvider()) { entry in
            TodaysPlanWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Plan")
        .description("The first workout scheduled for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct TodaysPlanEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let scheduledTime: String
}

struct TodaysPlanProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodaysPlanEntry {
        .init(date: Date(), title: "Full-Body Strength",
              subtitle: "30 min \u{00b7} Strength",
              scheduledTime: "5:30 PM")
    }
    func getSnapshot(in context: Context, completion: @escaping (TodaysPlanEntry) -> Void) {
        completion(currentEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaysPlanEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()],
                            policy: .after(Date().addingTimeInterval(60 * 60))))
    }

    private func currentEntry() -> TodaysPlanEntry {
        let defaults = UserDefaults(suiteName: "group.com.fitfusion")
        let title = defaults?.string(forKey: "todaysPlanTitle") ?? "No plan yet"
        let subtitle = defaults?.string(forKey: "todaysPlanSubtitle") ?? "Tap to plan one"
        let time = defaults?.string(forKey: "todaysPlanTime") ?? ""
        return .init(date: Date(), title: title, subtitle: subtitle, scheduledTime: time)
    }
}

struct TodaysPlanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodaysPlanEntry

    var body: some View {
        switch family {
        case .systemSmall, .systemMedium:
            VStack(alignment: .leading, spacing: 4) {
                Label("Today's Plan", systemImage: "calendar.badge.clock")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                Text(entry.title).font(.headline).lineLimit(2)
                Text(entry.subtitle).font(.caption2).foregroundStyle(.secondary)
                if !entry.scheduledTime.isEmpty {
                    Text(entry.scheduledTime).font(.caption).foregroundStyle(.indigo)
                }
                Spacer()
            }
            .padding(10)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title).font(.caption.weight(.semibold))
                Text(entry.subtitle).font(.caption2).foregroundStyle(.secondary)
                if !entry.scheduledTime.isEmpty {
                    Text(entry.scheduledTime).font(.caption2)
                }
            }
        default:
            Text(entry.title)
        }
    }
}
