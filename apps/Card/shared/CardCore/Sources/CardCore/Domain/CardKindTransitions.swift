// CardKindTransitions — pure logic for note ↔ task ↔ reminder transitions.
// Mirrored in android/core/.../domain/CardKindTransitions.kt
import Foundation

public enum CardKindTransitions {
    /// Convert `card` to `target`. Clears the irrelevant fields per kind.
    /// For `.reminder`, `reminderAt` MUST be in the future or this returns `nil`.
    public static func convert(
        _ card: Card,
        to target: CardKind,
        reminderAt: Date? = nil,
        now: Date = Date()
    ) -> Card? {
        if card.kind == target && target != .reminder {
            // Identity transition for non-reminder kinds is a no-op.
            return card
        }

        var updated = card
        updated.kind = target
        updated.updatedAt = now

        switch target {
        case .note:
            updated.reminderAt = nil
            updated.completedAt = nil
        case .task:
            updated.reminderAt = nil
            // completedAt preserved if already set
        case .reminder:
            guard let when = reminderAt, when > now else { return nil }
            updated.reminderAt = when
            updated.completedAt = nil
        }
        return updated
    }

    /// Toggle a task's completion state. No-op for non-tasks.
    public static func toggleCompleted(_ card: Card, now: Date = Date()) -> Card {
        guard card.kind == .task else { return card }
        var updated = card
        updated.completedAt = card.isCompleted ? nil : now
        updated.updatedAt = now
        return updated
    }
}
