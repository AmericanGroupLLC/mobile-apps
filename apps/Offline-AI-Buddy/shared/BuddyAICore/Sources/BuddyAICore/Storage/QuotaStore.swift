import Foundation

/// Per-profile, per-day quota state. Single file holds every profile's
/// entry; rolls over at local midnight.
public final class QuotaStore {

    private let url: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "offlineaibuddy.quota")

    public init(directory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let base: URL
        if let directory {
            base = directory
        } else {
            base = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("offlineaibuddy", isDirectory: true)
        }
        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        self.url = base.appendingPathComponent("quota.json")
    }

    public func load() -> [QuotaState] {
        queue.sync {
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([QuotaState].self, from: data) else {
                return []
            }
            return decoded
        }
    }

    public func save(_ states: [QuotaState]) throws {
        try queue.sync {
            let data = try JSONEncoder().encode(states)
            try data.write(to: url, options: .atomic)
        }
    }

    public func get(for profileId: UUID, day: String) -> QuotaState {
        let all = load()
        if let s = all.first(where: { $0.profileId == profileId && $0.day == day }) {
            return s
        }
        return QuotaState(profileId: profileId, day: day)
    }

    public func upsert(_ state: QuotaState) throws {
        var all = load()
        if let idx = all.firstIndex(where: { $0.profileId == state.profileId && $0.day == state.day }) {
            all[idx] = state
        } else {
            all.append(state)
        }
        // Keep at most 7 days per profile (rolling window).
        let grouped = Dictionary(grouping: all, by: { $0.profileId })
        var trimmed: [QuotaState] = []
        for (_, days) in grouped {
            let sorted = days.sorted { $0.day > $1.day }
            trimmed.append(contentsOf: sorted.prefix(7))
        }
        try save(trimmed)
    }
}
