// CardSorter — pure feed-sort logic.
// Mirrored in android/core/.../domain/CardSorter.kt
//
// Sort order (top → bottom):
//   1. Reminders due in the next 24h (closest fire-time first)
//   2. All other reminders / notes / tasks (newest updatedAt first)
//   3. Completed tasks (most recently completed first)
import Foundation

public enum CardSorter {
    public static func sort(_ cards: [Card], now: Date = Date()) -> [Card] {
        let dueSoonCutoff = now.addingTimeInterval(24 * 60 * 60)

        let dueSoon = cards
            .filter { card in
                card.kind == .reminder
                    && !card.isCompleted
                    && (card.reminderAt.map { $0 > now && $0 <= dueSoonCutoff } ?? false)
            }
            .sorted { ($0.reminderAt ?? .distantFuture) < ($1.reminderAt ?? .distantFuture) }

        let dueSoonIDs = Set(dueSoon.map { $0.id })

        let middle = cards
            .filter { !dueSoonIDs.contains($0.id) && !$0.isCompleted }
            .sorted { $0.updatedAt > $1.updatedAt }

        let bottom = cards
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        return dueSoon + middle + bottom
    }
}
