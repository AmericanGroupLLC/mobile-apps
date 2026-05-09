import Foundation
import Combine
import BuddyCore

/// SwiftUI-friendly wrapper around `BuddyCore.LocalRivalryStore`.
@MainActor
final class RivalriesModel: ObservableObject {
    @Published private(set) var rivalries: [Rivalry] = []
    private let store: LocalRivalryStore

    init() {
        // If the store fails to initialise (rare), fall back to a fresh
        // in-memory directory so the app keeps working.
        do {
            self.store = try LocalRivalryStore()
        } catch {
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("buddyplay-fallback")
            self.store = (try? LocalRivalryStore(directory: temp))
                ?? (try! LocalRivalryStore(directory: FileManager.default.temporaryDirectory))
        }
        reload()
    }

    func reload() {
        rivalries = store.loadAll().sorted { $0.lastPlayedAt > $1.lastPlayedAt }
    }

    func record(opponentId: UUID, opponentName: String, kind: GameKind, outcome: Rivalry.Outcome) {
        store.record(opponentId: opponentId, opponentName: opponentName, kind: kind, outcome: outcome)
        reload()
    }

    func eraseAll() {
        store.eraseAll()
        reload()
    }
}
