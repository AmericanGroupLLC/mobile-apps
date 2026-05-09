import Foundation

/// Per-profile JSON file holding chat history. Capped at 200 messages
/// per profile (oldest dropped).
public final class ChatHistoryStore {

    public static let maxMessagesPerProfile: Int = 200

    private let directory: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "offlineaibuddy.chathistory")

    public init(directory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let base: URL
        if let directory {
            base = directory
        } else {
            base = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("offlineaibuddy", isDirectory: true)
                .appendingPathComponent("chats", isDirectory: true)
        }
        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        self.directory = base
    }

    private func url(for profileId: UUID) -> URL {
        directory.appendingPathComponent("\(profileId.uuidString).json")
    }

    public func load(for profileId: UUID) -> [ChatSession] {
        queue.sync {
            guard let data = try? Data(contentsOf: url(for: profileId)),
                  let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else {
                return []
            }
            return decoded
        }
    }

    public func save(_ sessions: [ChatSession], for profileId: UUID) throws {
        try queue.sync {
            let trimmed = trim(sessions)
            let data = try JSONEncoder().encode(trimmed)
            try data.write(to: url(for: profileId), options: .atomic)
        }
    }

    public func eraseAll(for profileId: UUID) {
        _ = queue.sync { try? fileManager.removeItem(at: url(for: profileId)) }
    }

    public func eraseAll() {
        _ = queue.sync { try? fileManager.removeItem(at: directory) }
        _ = try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func trim(_ sessions: [ChatSession]) -> [ChatSession] {
        let total = sessions.reduce(0) { $0 + $1.messages.count }
        guard total > Self.maxMessagesPerProfile else { return sessions }
        // Drop oldest sessions until we're under the cap.
        var sorted = sessions.sorted { $0.startedAt < $1.startedAt }
        var current = total
        while current > Self.maxMessagesPerProfile && !sorted.isEmpty {
            let removed = sorted.removeFirst()
            current -= removed.messages.count
        }
        return sorted
    }
}
