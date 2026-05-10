import WidgetKit
import SwiftUI

struct ReadinessEntry: TimelineEntry {
    let date: Date
    let score: Int
    let suggestion: String
}

struct ReadinessProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadinessEntry {
        ReadinessEntry(date: Date(), score: 78, suggestion: "Solid day — moderate effort")
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 30 minutes — iOS writes to App Group via ReadinessEngine.
        let next = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> ReadinessEntry {
        let defaults = UserDefaults(suiteName: "group.com.fitfusion")
        let score = defaults?.integer(forKey: "readinessScore") ?? 0
        let suggestion = defaults?.string(forKey: "readinessSuggestion") ?? "Open FitFusion"
        return ReadinessEntry(date: Date(),
                              score: score == 0 ? 50 : score,
                              suggestion: suggestion)
    }
}
