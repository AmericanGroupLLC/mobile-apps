// AlarmStore — JSON-on-disk persistence for alarms. Pure Foundation.
import Foundation

public protocol AlarmStoring: AnyObject {
    func load() -> [Alarm]
    func save(_ alarms: [Alarm]) throws
}

public final class AlarmStore: AlarmStoring {
    private let url: URL
    private let fileManager: FileManager

    public init(directory: URL, filename: String = "pocket-alarms.json", fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.url = directory.appendingPathComponent(filename)
    }

    public func load() -> [Alarm] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            return []
        }
    }

    public func save(_ alarms: [Alarm]) throws {
        let data = try JSONEncoder().encode(alarms)
        let dir = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try data.write(to: url, options: .atomic)
    }
}
