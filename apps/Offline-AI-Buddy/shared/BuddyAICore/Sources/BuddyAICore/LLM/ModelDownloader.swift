import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Background-friendly downloader for the GGUF model file. iOS app
/// configures a `URLSession` background config; on macOS / tests we
/// fall back to a foreground session.
public actor ModelDownloader {

    public struct Progress: Sendable {
        public let bytesWritten: Int64
        public let totalBytes: Int64
        public var fraction: Double {
            totalBytes <= 0 ? 0 : Double(bytesWritten) / Double(totalBytes)
        }
    }

    public enum DownloaderError: Error, Sendable {
        case allMirrorsFailed
        case sha256Mismatch(expected: String, got: String)
        case ioError(Error)
    }

    private let session: URLSession
    private let manifest: ModelManifest
    private let store: ModelStore

    public init(manifest: ModelManifest, store: ModelStore, session: URLSession = .shared) {
        self.manifest = manifest
        self.store = store
        self.session = session
    }

    /// Try each mirror in order. Verify SHA-256 (skip when manifest's
    /// sha256 is empty — dev mode). Move into `ModelStore`. Reports
    /// progress via `onProgress`.
    public func download(onProgress: @escaping @Sendable (Progress) -> Void = { _ in }) async throws -> URL {
        for url in manifest.urls {
            do {
                let tmp = try await downloadOne(from: url, onProgress: onProgress)
                if !manifest.sha256.isEmpty {
                    let actual = ModelDownloader.sha256(of: tmp)
                    guard actual.lowercased() == manifest.sha256.lowercased() else {
                        try? FileManager.default.removeItem(at: tmp)
                        throw DownloaderError.sha256Mismatch(expected: manifest.sha256, got: actual)
                    }
                }
                return try store.install(downloaded: tmp, named: "\(manifest.name).gguf")
            } catch {
                continue
            }
        }
        throw DownloaderError.allMirrorsFailed
    }

    private func downloadOne(
        from url: URL,
        onProgress: @escaping @Sendable (Progress) -> Void
    ) async throws -> URL {
        let (tmpURL, response) = try await session.download(from: url)
        let total = (response as? HTTPURLResponse)?.expectedContentLength ?? -1
        let bytes = (try? FileManager.default.attributesOfItem(atPath: tmpURL.path)[.size] as? Int64) ?? -1
        onProgress(Progress(bytesWritten: bytes, totalBytes: max(total, bytes)))
        return tmpURL
    }

    /// SHA-256 hex digest of a file. CryptoKit-backed when available,
    /// stub fallback otherwise (returns empty string — only used in
    /// dev mode where manifest.sha256 is also empty).
    public static func sha256(of url: URL) -> String {
        #if canImport(CryptoKit)
        guard let stream = InputStream(url: url) else { return "" }
        stream.open()
        defer { stream.close() }
        var hasher = SHA256()
        let bufSize = 1024 * 1024
        var buf = [UInt8](repeating: 0, count: bufSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buf, maxLength: bufSize)
            if read <= 0 { break }
            hasher.update(data: Data(bytes: buf, count: read))
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
        #else
        return ""
        #endif
    }
}
