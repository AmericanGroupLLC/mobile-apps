import Foundation
import Combine
import CardCore

/// `@Published` state on top of `CardStore`. The Share Extension writes
/// directly to the same App Group container, so on each `foreground` we
/// reload from disk to surface those writes.
@MainActor
final class CardRepository: ObservableObject {
    static let shared = CardRepository()

    @Published private(set) var cards: [Card] = []

    private let store: CardStoring
    private let reminders = ReminderService.shared

    init(store: CardStoring? = nil) {
        if let s = store {
            self.store = s
        } else if let appGroup = CardStore.appGroup() {
            self.store = appGroup
        } else {
            // Fallback: per-process Documents directory (e.g. unit tests).
            let docs = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
            self.store = CardStore(directory: docs)
        }
        reload()
    }

    func reload() {
        cards = CardSorter.sort(store.load())
    }

    func capture(text: String, kind: CardKind = .note, surface: Surface = .app) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let card = Card(text: trimmed, kind: kind)
        upsert(card)
        AnalyticsService.shared.track(.cardCaptured(surface: surface, kind: kind))
    }

    func upsert(_ card: Card) {
        var current = store.load()
        current.removeAll { $0.id == card.id }
        current.append(card)
        try? store.save(current)
        if card.kind == .reminder, let at = card.reminderAt {
            reminders.schedule(card: card, at: at, surface: .app)
        } else {
            reminders.cancel(cardId: card.id)
        }
        reload()
    }

    func update(_ card: Card, text: String) {
        var updated = card
        updated.text = text
        updated.updatedAt = Date()
        upsert(updated)
    }

    func convert(_ card: Card, to kind: CardKind, reminderAt: Date? = nil) {
        guard let next = CardKindTransitions.convert(card, to: kind, reminderAt: reminderAt) else { return }
        AnalyticsService.shared.track(.cardConverted(from: card.kind, to: kind))
        upsert(next)
    }

    func toggleCompleted(_ card: Card) {
        upsert(CardKindTransitions.toggleCompleted(card))
    }

    func delete(_ card: Card) {
        var current = store.load()
        current.removeAll { $0.id == card.id }
        try? store.save(current)
        reminders.cancel(cardId: card.id)
        AnalyticsService.shared.track(.cardDeleted(kind: card.kind))
        reload()
    }

    func eraseAll() {
        try? store.save([])
        for c in cards { reminders.cancel(cardId: c.id) }
        reload()
    }
}
