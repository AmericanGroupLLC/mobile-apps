import XCTest
@testable import BuddyAICore

/// LlamaRunner smoke test — uses the StubLlamaBackend so it's always
/// safe to run in CI. The "real" smoke test (gated behind
/// RUN_LLAMA_SMOKE=1) requires the ~1 GB GGUF on disk and is run
/// locally / on manual CI dispatch.
final class GoldenTranslationTests: XCTestCase {

    func testStubBackendStreamsTokens() async throws {
        let runner = LlamaRunner(backend: StubLlamaBackend())
        try await runner.load(modelURL: URL(fileURLWithPath: "/dev/null"))
        let stream = await runner.generate(
            systemPrompt: "system",
            messages: [ChatMessage(role: .user, text: "hi")],
            options: .default
        )
        var collected = ""
        for await token in stream {
            collected += token.text
            if token.isLast { break }
        }
        XCTAssertTrue(collected.contains("hi"))
    }

    func testRealLlamaSmokeGated() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_LLAMA_SMOKE"] == "1",
                          "set RUN_LLAMA_SMOKE=1 to run the real LlamaRunner smoke test")
        // Real impl would load the GGUF from ModelStore and generate
        // 5 tokens. Lands when the iOS app target wires the real
        // LlamaCppBackend.
    }
}
