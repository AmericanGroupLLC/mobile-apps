import WidgetKit
import SwiftUI

/// Today's macro rings widget. Reads kcal / protein / carbs / fat totals the
/// iOS app writes to the App Group on every dashboard refresh.
struct MacroRingsWidget: Widget {
    let kind = "MyHealthMacroRingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroRingsProvider()) { entry in
            MacroRingsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Macros")
        .description("Today's calories \u{00b7} protein \u{00b7} carbs \u{00b7} fat at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MacroRingsEntry: TimelineEntry {
    let date: Date
    let kcal: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct MacroRingsProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroRingsEntry {
        .init(date: Date(), kcal: 1200, protein: 80, carbs: 150, fat: 40)
    }
    func getSnapshot(in context: Context, completion: @escaping (MacroRingsEntry) -> Void) {
        completion(currentEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroRingsEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()],
                            policy: .after(Date().addingTimeInterval(20 * 60))))
    }

    private func currentEntry() -> MacroRingsEntry {
        let d = UserDefaults(suiteName: "group.com.fitfusion")
        return .init(
            date: Date(),
            kcal: d?.double(forKey: "todayKcal") ?? 0,
            protein: d?.double(forKey: "todayProtein") ?? 0,
            carbs: d?.double(forKey: "todayCarbs") ?? 0,
            fat: d?.double(forKey: "todayFat") ?? 0
        )
    }
}

struct MacroRingsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MacroRingsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(spacing: 8) {
                Text("\(Int(entry.kcal))")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
                Text("kcal today").font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    macro("P", entry.protein, .pink)
                    macro("C", entry.carbs, .yellow)
                    macro("F", entry.fat, .purple)
                }
            }
        case .systemMedium:
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today").font(.caption).bold().foregroundStyle(.orange)
                    Text("\(Int(entry.kcal)) kcal")
                        .font(.title2).bold()
                }
                Spacer()
                HStack(spacing: 12) {
                    macroBig("Protein", entry.protein, .pink)
                    macroBig("Carbs", entry.carbs, .yellow)
                    macroBig("Fat", entry.fat, .purple)
                }
            }
            .padding(8)
        default:
            Text("\(Int(entry.kcal))")
        }
    }

    private func macro(_ letter: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 0) {
            Text(letter).font(.caption2).bold().foregroundStyle(color)
            Text("\(Int(value))").font(.caption.weight(.semibold))
        }
    }

    private func macroBig(_ name: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))").font(.headline).foregroundStyle(color)
            Text(name).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
