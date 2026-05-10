import WidgetKit
import SwiftUI

@main
struct PocketComplicationBundle: WidgetBundle {
    var body: some Widget {
        NextAlarmComplication()
    }
}

struct NextAlarmComplication: Widget {
    let kind = "NextAlarmComplication"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextAlarmProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Pocket")
        .description("Next alarm or current time.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct NextAlarmEntry: TimelineEntry {
    let date: Date
    let nextAlarm: Date?
}

struct NextAlarmProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextAlarmEntry { NextAlarmEntry(date: .now, nextAlarm: nil) }
    func getSnapshot(in context: Context, completion: @escaping (NextAlarmEntry) -> Void) {
        completion(NextAlarmEntry(date: .now, nextAlarm: nil))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextAlarmEntry>) -> Void) {
        let entry = NextAlarmEntry(date: .now, nextAlarm: nil)
        let next = Date().addingTimeInterval(60 * 15)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct ComplicationView: View {
    let entry: NextAlarmEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 1) {
                Image(systemName: "alarm").font(.caption)
                Text(entry.nextAlarm ?? entry.date, format: .dateTime.hour().minute()).font(.caption2.monospacedDigit())
            }
        case .accessoryInline:
            Text("Pocket • \(entry.nextAlarm ?? entry.date, format: .dateTime.hour().minute())")
        default:
            HStack {
                Image(systemName: "alarm")
                Text(entry.nextAlarm ?? entry.date, format: .dateTime.hour().minute())
            }
        }
    }
}
