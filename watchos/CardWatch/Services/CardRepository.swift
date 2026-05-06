import Foundation
import Combine
import CardCore

/// Watch-side repository. Same `CardStore` shape, scoped to the watch's
/// own Documents (the App Group is read-only / synced via WCSession on
/// real devices; for v1 the watch keeps its own feed and the iPhone keeps
/// its own).
@MainActor
final class WatchCardRepository: ObservableObject {
    static let shared = WatchCardRepository()

    @Published private(set) var cards: [Card] = []
    private let store: CardStoring

    init(store: CardStoring? = nil) {
        if let s = store {
            self.store = s
        } else {
            let docs = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
            self.store = CardStore(directory: docs)
        }
        reload()
    }

    func reload() {
        cards = CardSorter.sort(store.load())
    }

    func capture(text: String, surface: Surface = .watch) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = store.load()
        current.append(Card(text: trimmed))
        try? store.save(current)
        AnalyticsService.shared.track(.cardCaptured(surface: surface, kind: .note))
        reload()
    }

    func delete(_ card: Card) {
        var current = store.load()
        current.removeAll { $0.id == card.id }
        try? store.save(current)
        reload()
    }
}
