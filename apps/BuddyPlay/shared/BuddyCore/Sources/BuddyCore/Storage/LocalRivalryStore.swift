import Foundation

/// JSON-on-disk store for cumulative head-to-head records. Single file,
/// single process — no need for App Groups or atomic file replace.
public final class LocalRivalryStore {

    private let url: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "buddyplay.rivalrystore")

    public init(directory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let base: URL
        if let directory {
            base = directory
        } else {
            base = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("buddyplay", isDirectory: true)
        }
        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        self.url = base.appendingPathComponent("rivalries.json")
    }

    /// Load every rivalry. Returns an empty list if the file doesn't yet
    /// exist or if the JSON is corrupt (corruption falls back to empty so a
    /// single bad write can never brick the screen).
    public func loadAll() -> [Rivalry] {
        queue.sync {
            guard let data = try? Data(contentsOf: url) else { return [] }
            do {
                return try JSONDecoder().decode([Rivalry].self, from: data)
            } catch {
                return []
            }
        }
    }

    public func load(opponentId: UUID) -> Rivalry? {
        loadAll().first { $0.opponentId == opponentId }
    }

    /// Record one game outcome. Idempotent over `(opponentId, kind)`: every
    /// call increments tallies by exactly one.
    public func record(
        opponentId: UUID,
        opponentName: String,
        kind: GameKind,
        outcome: Rivalry.Outcome,
        at date: Date = Date()
    ) {
        queue.sync {
            var all = loadInternal()
            if let idx = all.firstIndex(where: { $0.opponentId == opponentId }) {
                var r = all[idx]
                r.opponentName = opponentName  // keep latest display name
                r.record(outcome, for: kind, at: date)
                all[idx] = r
            } else {
                var r = Rivalry(opponentId: opponentId, opponentName: opponentName, lastPlayedAt: date)
                r.record(outcome, for: kind, at: date)
                all.append(r)
            }
            saveInternal(all)
        }
    }

    /// Wipe all rivalries.
    public func eraseAll() {
        queue.sync {
            try? fileManager.removeItem(at: url)
        }
    }

    // MARK: - Internal

    private func loadInternal() -> [Rivalry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Rivalry].self, from: data)) ?? []
    }

    private func saveInternal(_ rivalries: [Rivalry]) {
        let data = try? JSONEncoder().encode(rivalries)
        try? data?.write(to: url, options: .atomic)
    }
}
