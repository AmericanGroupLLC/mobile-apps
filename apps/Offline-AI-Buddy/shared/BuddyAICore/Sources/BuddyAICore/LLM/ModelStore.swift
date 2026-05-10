import Foundation

/// On-disk layout for the GGUF model file. Single file in v1; v1.1's
/// model marketplace will use the same `models/` directory with one
/// file per manifest entry.
public final class ModelStore {

    public let directory: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let base: URL
        if let directory {
            base = directory
        } else {
            base = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("offlineaibuddy", isDirectory: true)
                .appendingPathComponent("models", isDirectory: true)
        }
        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        self.directory = base
    }

    public func url(forModelNamed name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    public func isInstalled(named name: String) -> Bool {
        fileManager.fileExists(atPath: url(forModelNamed: name).path)
    }

    /// Move a downloaded file into the store. Atomic replace.
    @discardableResult
    public func install(downloaded source: URL, named name: String) throws -> URL {
        let dest = url(forModelNamed: name)
        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        try fileManager.moveItem(at: source, to: dest)
        return dest
    }

    public func remove(named name: String) throws {
        let target = url(forModelNamed: name)
        if fileManager.fileExists(atPath: target.path) {
            try fileManager.removeItem(at: target)
        }
    }

    /// Verify the SHA-256 of an installed model. `expected` of `""`
    /// counts as "skip verification" (dev mode).
    public func verify(named name: String, expectedSHA256 expected: String) -> Bool {
        if expected.isEmpty { return true }
        let actual = ModelDownloader.sha256(of: url(forModelNamed: name))
        return actual.lowercased() == expected.lowercased()
    }
}
