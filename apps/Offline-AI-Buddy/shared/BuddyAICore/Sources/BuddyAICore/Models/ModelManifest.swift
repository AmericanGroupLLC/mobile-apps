import Foundation

/// Static description of a downloadable GGUF model. v1 ships exactly one
/// of these (Qwen2.5-1.5B-Instruct-Q4_K_M); v1.1 will introduce a
/// catalogue.
public struct ModelManifest: Codable, Hashable, Sendable {
    public let name: String
    public let version: Int
    public let urls: [URL]                  // mirrors, tried in order
    public let sizeBytes: Int64
    public let sha256: String               // hex
    public let contextSize: Int
    public let minDeviceRAM: Int64          // bytes; below this we warn

    public init(
        name: String,
        version: Int,
        urls: [URL],
        sizeBytes: Int64,
        sha256: String,
        contextSize: Int,
        minDeviceRAM: Int64
    ) {
        self.name = name
        self.version = version
        self.urls = urls
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
        self.contextSize = contextSize
        self.minDeviceRAM = minDeviceRAM
    }

    /// The default v1.0 model. SHA-256 is set to placeholder until the
    /// first build downloads + verifies it; `ModelDownloader` falls open
    /// when sha256 is empty (dev mode).
    public static let defaultV1: ModelManifest = ModelManifest(
        name: "Qwen2.5-1.5B-Instruct-Q4_K_M",
        version: 1,
        urls: [
            URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf")!,
            URL(string: "https://huggingface.co/lmstudio-community/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf")!,
        ],
        sizeBytes: 1_073_741_824,
        sha256: "",            // set in MODELS.md when first build verified
        contextSize: 4096,
        minDeviceRAM: 3_500_000_000
    )
}
