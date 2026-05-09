// CardStore — JSON-on-disk persistence. App-Group-aware: pass the App Group
// container URL on the main app so the iOS Share Extension reads/writes the
// same file. Pure Foundation; safe to call from any thread that owns its
// instance.
import Foundation

public protocol CardStoring: AnyObject {
    func load() -> [Card]
    func save(_ cards: [Card]) throws
}

public final class CardStore: CardStoring {
    private let url: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        directory: URL,
        filename: String = "card-feed.json",
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.url = directory.appendingPathComponent(filename)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    /// Convenience initializer that resolves the App Group container URL.
    /// Returns `nil` on platforms / configurations where the App Group is not
    /// available (e.g. unit tests). Callers should fall back to a per-process
    /// directory in that case.
    public static func appGroup(
        identifier: String = "group.com.americangroupllc.card",
        filename: String = "card-feed.json",
        fileManager: FileManager = .default
    ) -> CardStore? {
        guard let dir = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else { return nil }
        return CardStore(directory: dir, filename: filename, fileManager: fileManager)
    }

    public func load() -> [Card] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([Card].self, from: data)
        } catch {
            // Corrupt store → start fresh; never crash the app on launch.
            return []
        }
    }

    public func save(_ cards: [Card]) throws {
        let data = try encoder.encode(cards)
        let dir = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try data.write(to: url, options: .atomic)
    }
}
