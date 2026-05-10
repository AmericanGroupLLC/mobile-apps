import Foundation

/// Rule-based badge awarder. Evaluates the supplied `Snapshot` and awards any
/// missing badges via `CloudStore.awardBadge` (idempotent). Rules can be
/// extended trivially \u{2014} each badge is a `(slug, title, subtitle, predicate)`.
@MainActor
public final class BadgesEngine {

    public static let shared = BadgesEngine()
    private init() {}

    public struct Snapshot {
        public let workoutsThisWeek: Int
        public let totalKmThisWeek: Double
        public let longestStreakDays: Int
        public let mindfulMinutesThisWeek: Int

        public init(workoutsThisWeek: Int, totalKmThisWeek: Double,
                    longestStreakDays: Int, mindfulMinutesThisWeek: Int) {
            self.workoutsThisWeek = workoutsThisWeek
            self.totalKmThisWeek = totalKmThisWeek
            self.longestStreakDays = longestStreakDays
            self.mindfulMinutesThisWeek = mindfulMinutesThisWeek
        }
    }

    private struct Rule {
        let slug: String
        let title: String
        let subtitle: String
        let predicate: (Snapshot) -> Bool
    }

    private let rules: [Rule] = [
        .init(slug: "first-workout",        title: "First Sweat",
              subtitle: "Logged your first workout this week.") { $0.workoutsThisWeek >= 1 },
        .init(slug: "five-workouts",        title: "Crushing It",
              subtitle: "Five workouts in a single week.") { $0.workoutsThisWeek >= 5 },
        .init(slug: "10k-week",             title: "10K Week",
              subtitle: "Ran 10+ km this week.") { $0.totalKmThisWeek >= 10 },
        .init(slug: "streak-7",             title: "Week-Long Streak",
              subtitle: "Hit your daily goal 7 days in a row.") { $0.longestStreakDays >= 7 },
        .init(slug: "mindful-30",           title: "Mind Matters",
              subtitle: "30+ mindful minutes this week.") { $0.mindfulMinutesThisWeek >= 30 },
    ]

    /// Returns the slugs of newly-awarded badges (those not yet in CloudStore).
    @discardableResult
    public func evaluate(snapshot: Snapshot) -> [String] {
        var awarded: [String] = []
        for rule in rules where rule.predicate(snapshot) {
            _ = CloudStore.shared.awardBadge(slug: rule.slug,
                                             title: rule.title,
                                             subtitle: rule.subtitle)
            awarded.append(rule.slug)
        }
        return awarded
    }
}
