import WidgetKit
import SwiftUI
import DriftCore

/// Drift's WidgetKit complication. Shows the active discovery layer
/// (small dot) and the unread match count.
@main
struct DriftMatchesComplicationBundle: WidgetBundle {
    var body: some Widget {
        MatchesComplication()
    }
}

struct MatchesComplication: Widget {
    let kind = "MatchesComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MatchesEntryView(entry: entry)
        }
        .configurationDisplayName("Drift")
        .description("Layer + unread match count.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct LayerEntry: TimelineEntry {
    let date: Date
    let layer: Layer
    let unread: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LayerEntry {
        LayerEntry(date: Date(), layer: .zip, unread: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (LayerEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LayerEntry>) -> Void) {
        let entry = LayerEntry(date: Date(), layer: .zip, unread: 0)
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct MatchesEntryView: View {
    let entry: LayerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(.tint, lineWidth: 2)
                Text(layerSymbol(entry.layer))
            }
        case .accessoryInline:
            Text("Drift • \(layerSymbol(entry.layer)) • \(entry.unread)")
        default:
            HStack {
                Text(layerSymbol(entry.layer)).bold()
                Text("\(entry.unread) new")
            }
        }
    }

    private func layerSymbol(_ l: Layer) -> String {
        switch l {
        case .zip:    return "ZIP"
        case .county: return "CTY"
        case .state:  return "ST"
        case .server: return "SRV"
        }
    }
}
