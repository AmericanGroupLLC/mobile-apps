import WidgetKit
import SwiftUI

struct ReadinessWidget: Widget {
    let kind = "ReadinessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessProvider()) { entry in
            ReadinessWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Readiness")
        .description("Today's FitFusion readiness score on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner,
        ])
    }
}

struct ReadinessWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReadinessEntry

    var body: some View {
        switch family {
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
            Text("FitFusion · \(entry.score)")

        case .accessoryCorner:
            Text("\(entry.score)")
                .widgetCurvesContent()
                .widgetLabel("Readiness")

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
