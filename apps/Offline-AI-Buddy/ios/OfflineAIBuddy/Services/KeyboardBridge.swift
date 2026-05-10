import Foundation
import BuddyAICore
#if canImport(UIKit)
import UIKit
#endif

/// Listens for Darwin notifications posted by the keyboard extension,
/// reads the request from the App Group shared file, runs inference
/// through `LlamaService`, and writes 3 suggestions back. Documented
/// in `KEYBOARD.md`.
@MainActor
final class KeyboardBridge: ObservableObject {

    static let appGroupId = "group.com.americangroupllc.offlineaibuddy"
    static let requestNotification = "com.americangroupllc.offlineaibuddy.kb.request"
    static let replyNotification = "com.americangroupllc.offlineaibuddy.kb.reply"

    private weak var llama: LlamaService?

    init(llama: LlamaService) {
        self.llama = llama
    }

    func startListening() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let bridge = Unmanaged<KeyboardBridge>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in await bridge.handleRequest() }
            },
            Self.requestNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    /// Read the request file in the App Group; ask Llama for 3 short
    /// completions; write them back; post the reply notification.
    private func handleRequest() async {
        guard let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupId) else { return }
        let reqURL = containerURL.appendingPathComponent("keyboard.request.json")
        let replyURL = containerURL.appendingPathComponent("keyboard.reply.json")
        guard let data = try? Data(contentsOf: reqURL),
              let req = try? JSONDecoder().decode(KeyboardRequest.self, from: data) else { return }

        let suggestions = await fetchSuggestions(for: req.context)
        let reply = KeyboardReply(requestId: req.requestId, suggestions: suggestions)
        if let out = try? JSONEncoder().encode(reply) {
            try? out.write(to: replyURL, options: .atomic)
            CFNotificationCenterPostNotification(
                CFNotificationCenterGetDarwinNotifyCenter(),
                CFNotificationName(Self.replyNotification as CFString),
                nil, nil, true
            )
        }
    }

    private func fetchSuggestions(for context: String) async -> [String] {
        guard let llama else { return [] }
        let stream = llama.generate(
            kind: .chat,
            language: .en,
            isKidSafe: false,
            history: [],
            userInput: "Suggest 3 short replies (one per line) for this chat context: \"\(context)\"."
        )
        var collected = ""
        for await t in stream {
            collected += t.text
            if t.isLast { break }
        }
        return collected
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map(String.init)
    }
}

struct KeyboardRequest: Codable, Sendable {
    let requestId: String
    let context: String
}

struct KeyboardReply: Codable, Sendable {
    let requestId: String
    let suggestions: [String]
}
