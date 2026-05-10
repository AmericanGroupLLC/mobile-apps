// ReminderScheduler — pure-Swift "next fire time" math. Platform layers wrap
// UNUserNotificationCenter / AlarmManager around the output of these helpers.
// Mirrored in android/core/.../domain/ReminderScheduler.kt
import Foundation

public enum ReminderScheduler {
    /// Returns the next valid fire-time for `target` relative to `now`.
    /// Returns `nil` if `target` is not strictly in the future.
    /// (Card v1 has no recurring reminders — this is just a future-only filter.)
    public static func nextFireTime(
        for target: Date,
        now: Date = Date()
    ) -> Date? {
        target > now ? target : nil
    }

    /// Group reminders that share the same calendar minute under a single fire-time.
    /// Returns a dictionary keyed by the floored-to-minute Date, with the count of
    /// cards in that minute. Used to collapse spammy notifications into a single
    /// grouped notification with a count badge.
    public static func groupByMinute(
        _ cards: [Card],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [Date: Int] {
        var bucket: [Date: Int] = [:]
        for card in cards {
            guard card.kind == .reminder, let at = card.reminderAt, at > now else { continue }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            guard let floored = calendar.date(from: comps) else { continue }
            bucket[floored, default: 0] += 1
        }
        return bucket
    }
}
