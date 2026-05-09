import Foundation

/// One generated token from the LLM.
public struct Token: Hashable, Sendable {
    public let text: String
    public let isLast: Bool

    public init(text: String, isLast: Bool = false) {
        self.text = text
        self.isLast = isLast
    }
}

/// Sampling/runtime knobs for one `generate(...)` call.
public struct GenerationOptions: Hashable, Sendable {
    public var maxTokens: Int
    public var temperature: Double
    public var topP: Double
    public var stopSequences: [String]

    public init(
        maxTokens: Int = 512,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        stopSequences: [String] = []
    ) {
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.stopSequences = stopSequences
    }

    public static let `default` = GenerationOptions()
}

/// Backend protocol so `LlamaRunner` can swap llama.cpp for MLC LLM /
/// Apple Foundation Models / a fake (in tests) without touching feature
/// code. The real iOS impl wraps llama.cpp via the SPM C target; the
/// real Android impl is a Kotlin twin in `:core` calling JNI.
public protocol LlamaBackend: Sendable {
    func loadModel(at url: URL, contextSize: Int) async throws
    func unloadModel() async
    /// Stream tokens for one `(systemPrompt, userPrompt)` turn given the
    /// running message history.
    func generate(
        systemPrompt: String,
        messages: [ChatMessage],
        options: GenerationOptions
    ) -> AsyncStream<Token>
    var isLoaded: Bool { get async }
}

/// `actor`-isolated wrapper around a `LlamaBackend`. Single API surface
/// the rest of the app uses; same shape on Apple and Android.
public actor LlamaRunner {

    private var backend: LlamaBackend
    public private(set) var manifest: ModelManifest

    public init(backend: LlamaBackend, manifest: ModelManifest = .defaultV1) {
        self.backend = backend
        self.manifest = manifest
    }

    public func swap(backend: LlamaBackend) async {
        await self.backend.unloadModel()
        self.backend = backend
    }

    public func load(modelURL: URL) async throws {
        try await backend.loadModel(at: modelURL, contextSize: manifest.contextSize)
    }

    public func unload() async {
        await backend.unloadModel()
    }

    public var isLoaded: Bool {
        get async { await backend.isLoaded }
    }

    /// The single inference API. `systemPrompt` is built by
    /// `PromptTemplates`. The return is an `AsyncStream` so the UI can
    /// render tokens as they arrive.
    public func generate(
        systemPrompt: String,
        messages: [ChatMessage],
        options: GenerationOptions = .default
    ) -> AsyncStream<Token> {
        backend.generate(systemPrompt: systemPrompt, messages: messages, options: options)
    }
}

/// In-memory backend used when no model is loaded — emits a canned
/// "thinking..." token stream. Useful in CI smoke tests + dev builds
/// before the GGUF is downloaded.
public final class StubLlamaBackend: LlamaBackend, @unchecked Sendable {

    public init() {}

    private var loaded = false

    public var isLoaded: Bool {
        get async { loaded }
    }

    public func loadModel(at url: URL, contextSize: Int) async throws {
        loaded = true
    }

    public func unloadModel() async {
        loaded = false
    }

    public func generate(
        systemPrompt: String,
        messages: [ChatMessage],
        options: GenerationOptions
    ) -> AsyncStream<Token> {
        // Echo the user's last message so smoke tests have something
        // deterministic to assert.
        let last = messages.reversed().first(where: { $0.role == .user })?.text ?? ""
        let pieces = ["(stub) ", "you said: ", last]
        return AsyncStream { continuation in
            Task {
                for (i, p) in pieces.enumerated() {
                    try? await Task.sleep(nanoseconds: 5_000_000)
                    continuation.yield(Token(text: p, isLast: i == pieces.count - 1))
                }
                continuation.finish()
            }
        }
    }
}
