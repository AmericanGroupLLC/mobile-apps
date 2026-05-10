import Foundation

/// Pure-Swift streak counter. Operates on day-bucketed metric values (e.g.
/// "any workout today", "any meal logged today", "10k+ steps today") and
/// persists the resulting current / longest streak via `CloudStore.upsertStreak`.
@MainActor
public final class StreaksEngine {

    public static let shared = StreaksEngine()
    private init() {}

    /// Records that the user satisfied `kind` on the given day. Returns the
    /// updated `(current, longest)` streak.
    @discardableResult
    public func recordDay(kind: String, day: Date = Date()) -> (current: Int, longest: Int) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: day)

        let existing = CloudStore.shared.fetchStreaks()
            .first { ($0.value(forKey: "kind") as? String) == kind }

        let lastDay = existing?.value(forKey: "lastDay") as? Date
        let prevCurrent = (existing?.value(forKey: "currentDays") as? Int32).map(Int.init) ?? 0
        let prevLongest = (existing?.value(forKey: "longestDays") as? Int32).map(Int.init) ?? 0

        let newCurrent: Int
        if let last = lastDay {
            let lastDayStart = cal.startOfDay(for: last)
            if cal.isDate(lastDayStart, inSameDayAs: today) {
                newCurrent = prevCurrent
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                      cal.isDate(lastDayStart, inSameDayAs: yesterday) {
                newCurrent = prevCurrent + 1
            } else {
                newCurrent = 1
            }
        } else {
            newCurrent = 1
        }

        let newLongest = max(prevLongest, newCurrent)
        _ = CloudStore.shared.upsertStreak(kind: kind,
                                           currentDays: newCurrent,
                                           longestDays: newLongest,
                                           lastDay: today)
        return (newCurrent, newLongest)
    }
}
