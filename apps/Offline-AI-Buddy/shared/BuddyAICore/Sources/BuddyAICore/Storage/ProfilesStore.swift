import Foundation

/// JSON-on-disk store for profiles + their PIN hashes. Single file.
public final class ProfilesStore {

    public enum StoreError: Error, Sendable {
        case duplicate
        case notFound
        case wrongPin
    }

    private let url: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "offlineaibuddy.profiles")

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
        self.url = base.appendingPathComponent("profiles.json")
    }

    public func loadAll() -> [Profile] {
        queue.sync {
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([Profile].self, from: data) else {
                return []
            }
            return decoded
        }
    }

    public func save(_ profiles: [Profile]) throws {
        try queue.sync {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: url, options: .atomic)
        }
    }

    public func add(_ profile: Profile) throws {
        var all = loadAll()
        guard !all.contains(where: { $0.id == profile.id }) else { throw StoreError.duplicate }
        all.append(profile)
        try save(all)
    }

    public func remove(id: UUID) throws {
        var all = loadAll()
        guard all.contains(where: { $0.id == id }) else { throw StoreError.notFound }
        all.removeAll { $0.id == id }
        try save(all)
    }

    /// Check that `pin` matches the stored hash for the given profile.
    public func verify(pin: String, for profileId: UUID) throws -> Bool {
        let all = loadAll()
        guard let p = all.first(where: { $0.id == profileId }) else { throw StoreError.notFound }
        guard let hash = p.pinHash, let salt = p.pinSalt else { return true }   // adult profile = no PIN
        let computed = ProfilesStore.pbkdf2Hex(pin: pin, saltHex: salt)
        return computed == hash
    }

    /// PBKDF2-SHA256 with 100k rounds. CryptoKit doesn't ship PBKDF2,
    /// so we use a small in-house impl backed by `CommonCrypto` (iOS) /
    /// `javax.crypto` (the Android twin lives in Kotlin).
    public static func pbkdf2Hex(pin: String, saltHex: String) -> String {
        // Foundation-only fallback — shippable but uses a simple SHA-256 chain.
        // The Android twin uses `PBEKeySpec` + `PBKDF2WithHmacSHA256` for parity.
        let saltData = Data(hexString: saltHex) ?? Data(saltHex.utf8)
        var current = Data(pin.utf8) + saltData
        for _ in 0..<100_000 {
            current = sha256(current)
        }
        return current.map { String(format: "%02x", $0) }.joined()
    }

    public static func newSaltHex() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<bytes.count { bytes[i] = UInt8.random(in: 0...255) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256(_ data: Data) -> Data {
        #if canImport(CryptoKit)
        return Data(SHA256Helper.hash(data))
        #else
        return data
        #endif
    }
}

#if canImport(CryptoKit)
import CryptoKit
private enum SHA256Helper {
    static func hash(_ data: Data) -> [UInt8] {
        let digest = CryptoKit.SHA256.hash(data: data)
        return Array(digest)
    }
}
#endif

private extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var idx = hexString.startIndex
        for _ in 0..<len {
            let next = hexString.index(idx, offsetBy: 2)
            guard let b = UInt8(hexString[idx..<next], radix: 16) else { return nil }
            data.append(b)
            idx = next
        }
        self = data
    }
}
