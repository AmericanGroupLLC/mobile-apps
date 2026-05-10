import Foundation
import BuddyAICore
import SwiftUI

/// App-side wrapper around `BuddyAICore.LlamaRunner`. Exposes published
/// state for SwiftUI + a stable `generate(...)` API.
@MainActor
final class LlamaService: ObservableObject {

    @Published private(set) var modelLoaded: Bool = false
    @Published private(set) var generating: Bool = false

    let runner: LlamaRunner
    let store: ModelStore
    let manifest: ModelManifest

    init(runner: LlamaRunner, store: ModelStore, manifest: ModelManifest) {
        self.runner = runner
        self.store = store
        self.manifest = manifest
    }

    /// Called on app launch — loads the model into the runner if it's
    /// already on disk. Otherwise the OnboardingFlow downloads it.
    func warmupIfModelPresent() async {
        let url = store.url(forModelNamed: "\(manifest.name).gguf")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try await runner.load(modelURL: url)
            modelLoaded = true
        } catch {
            modelLoaded = false
        }
    }

    /// Build a prompt + stream tokens. The caller owns the message
    /// history list it passes in.
    func generate(
        kind: ChatSession.Kind,
        language: Language,
        isKidSafe: Bool,
        history: [ChatMessage],
        userInput: String,
        translateSrc: Language? = nil,
        translateDst: Language? = nil
    ) -> AsyncStream<Token> {
        let prompt: PromptTemplates.Prompt
        if kind == .translate, let src = translateSrc, let dst = translateDst {
            prompt = TranslateOrchestrator.prompt(src: src, dst: dst, text: userInput)
        } else {
            let base = PromptTemplates.prompt(kind: kind, language: language, isKidSafe: isKidSafe)
            let rendered = base.render([
                "user": userInput,
                "date": ISO8601DateFormatter().string(from: Date()),
                "audience": "general",
            ])
            prompt = PromptTemplates.Prompt(system: base.system, userTemplate: rendered)
        }

        let messagesWithUser = history + [ChatMessage(role: .user, text: prompt.userTemplate)]
        generating = true
        let stream = AsyncStream<Token> { continuation in
            Task { [weak self] in
                guard let self else { continuation.finish(); return }
                let inner = await self.runner.generate(
                    systemPrompt: prompt.system,
                    messages: messagesWithUser
                )
                for await t in inner { continuation.yield(t) }
                continuation.finish()
                await MainActor.run { self.generating = false }
            }
        }
        return stream
    }
}
