import WidgetKit
import SwiftUI

/// "Card – Quick capture" complication. Tapping it deep-links to the
/// watch composer via a widgetURL.
@main
struct QuickCaptureComplication: Widget {
    let kind: String = "QuickCaptureComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickCaptureComplicationEntryView(entry: entry)
                .widgetURL(URL(string: "card://composer"))
        }
        .configurationDisplayName("Card – Quick capture")
        .description("Tap to add a Card without opening the app.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct QuickCaptureComplicationEntryView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(lineWidth: 2)
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
            }
        case .accessoryInline:
            Label("Capture", systemImage: "plus.bubble")
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label("Card", systemImage: "plus.bubble")
                    .font(.caption.bold())
                Text("Tap to capture")
                    .font(.caption2)
            }
        default:
            Image(systemName: "plus")
        }
    }
}
