import SwiftUI
import FitFusionCore

/// iOS news drawer — three inner tabs (Urgent · For You · Wellness) with
/// source badges (WHO, MyChart, CDC, NIH, SCC Health, …) per the design
/// spec. Mirrors `android/.../ui/news/NewsDrawerSheet.kt`. Shown as a
/// sheet from any tab's bell button.
public struct NewsDrawerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Int = 0

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Urgent").tag(0)
                    Text("For You").tag(1)
                    Text("Wellness").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(items.indices, id: \.self) { i in
                            NewsRow(item: items[i])
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Health news")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var items: [NewsItem] {
        switch tab {
        case 0: return urgent
        case 1: return forYou
        default: return wellness
        }
    }

    private let urgent: [NewsItem] = [
        NewsItem(source: "WHO", time: "2h ago",
                 title: "Measles advisory · Bay Area",
                 subtitle: "Check immunization status",
                 isUrgent: true),
        NewsItem(source: "MyChart", time: "5h ago",
                 title: "New lab results available",
                 subtitle: "A1C, lipid panel",
                 isUrgent: true),
    ]
    private let forYou: [NewsItem] = [
        NewsItem(source: "CDC", time: "Yesterday",
                 title: "DASH diet vs hypertension",
                 subtitle: "New trial results, 4 min read"),
        NewsItem(source: "NIH", time: "2 days ago",
                 title: "A1C and sleep quality",
                 subtitle: "How sleep shapes glucose"),
        NewsItem(source: "SCC Health", time: "3 days ago",
                 title: "Free BP screenings nearby",
                 subtitle: "Santa Clara County"),
    ]
    private let wellness: [NewsItem] = [
        NewsItem(source: "Care+", time: "Today",
                 title: "Hydration nudge",
                 subtitle: "You averaged 4 cups yesterday — aim for 8 today."),
        NewsItem(source: "Care+", time: "Today",
                 title: "Mindful minute",
                 subtitle: "Tap to try a 60-second breathing exercise."),
    ]
}

private struct NewsItem {
    let source: String
    let time: String
    let title: String
    let subtitle: String
    var isUrgent: Bool = false
}

private struct NewsRow: View {
    let item: NewsItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Color-coded urgent stripe on the leading edge.
            RoundedRectangle(cornerRadius: 2)
                .fill(item.isUrgent ? CarePlusPalette.danger : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.source)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(badgeColor(item.source).opacity(0.18), in: Capsule())
                        .foregroundStyle(badgeColor(item.source))
                    Text(item.time).font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                }
                Text(item.title).font(.subheadline.weight(.semibold))
                Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (item.isUrgent ? CarePlusPalette.danger.opacity(0.06)
                           : CarePlusPalette.surfaceElevated),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    /// Stable color per news source — mirrors the design-spec mockup.
    private func badgeColor(_ source: String) -> Color {
        switch source.uppercased() {
        case "WHO":         return CarePlusPalette.danger
        case "MYCHART":     return CarePlusPalette.careBlue
        case "CDC":         return CarePlusPalette.info
        case "NIH":         return CarePlusPalette.trainGreen
        case "SCC HEALTH":  return CarePlusPalette.warning
        case "CARE+":       return CarePlusPalette.dietCoral
        default:            return CarePlusPalette.onSurfaceMuted
        }
    }
}
