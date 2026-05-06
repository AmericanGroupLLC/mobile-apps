import Foundation
import BuddyAICore

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var streamingText: String = ""
    @Published var isStreaming: Bool = false
    @Published var showQuotaExhausted: Bool = false

    func append(_ m: ChatMessage) { messages.append(m) }

    /// Stream tokens, applying ContentPolicy on the rolling buffer if
    /// kid-safe is on. Final assistant message lands in `messages` once
    /// the stream finishes.
    func consume(_ stream: AsyncStream<Token>, isKidSafe: Bool, language: Language) async {
        isStreaming = true
        streamingText = ""
        let policy = ContentPolicy(language: language, isKidSafe: isKidSafe)
        for await token in stream {
            streamingText += token.text
            let r = policy.filter(streamingText)
            if r.blocked {
                streamingText = r.filtered
                break
            }
            if token.isLast { break }
        }
        isStreaming = false
        let final = streamingText
        streamingText = ""
        if !final.isEmpty {
            messages.append(ChatMessage(role: .assistant, text: final))
        }
    }
}
