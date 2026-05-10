import Foundation

/// Builds the system+user prompt that the `reply-suggest` Edge Function
/// sends to the LLM provider. Pure logic — no I/O. Mirrored case-for-case
/// in Kotlin and TypeScript.
public struct ReplyPromptBuilder {

    public struct Inputs: Equatable {
        public let viewer: Profile
        public let target: Profile
        public let lastMessages: [Message]    // chronological, oldest first; <= 5
        public let tone: Tone

        public init(viewer: Profile, target: Profile, lastMessages: [Message], tone: Tone) {
            self.viewer = viewer
            self.target = target
            self.lastMessages = lastMessages
            self.tone = tone
        }
    }

    public struct Output: Equatable {
        public let system: String
        public let user: String
    }

    public static func build(_ input: Inputs) -> Output {
        let toneClause = toneSpecificClause(input.tone)
        let system = """
            You write three short reply suggestions for a Drift dating app chat. \
            Return strict JSON: {"casual": ..., "context": ..., "playful": ...}. \
            Each suggestion is one sentence, ≤ 140 characters, no emoji unless playful, \
            and never asks for private location. \(toneClause)
            """

        let viewer = input.viewer
        let target = input.target
        let viewerVibes = viewer.vibeTags.isEmpty ? "—" : viewer.vibeTags.joined(separator: ", ")
        let targetVibes = target.vibeTags.isEmpty ? "—" : target.vibeTags.joined(separator: ", ")

        let messages = input.lastMessages.suffix(5)
        let messagesSection: String
        if messages.isEmpty {
            messagesSection = "(no messages yet — these are opener suggestions)"
        } else {
            messagesSection = messages.map { m in
                let label = m.authorId == viewer.id ? "A" : (m.authorId == target.id ? "B" : "?")
                return "\(label): \(m.text)"
            }.joined(separator: "\n")
        }

        let user = """
            Person A: \(viewer.displayName) (intent: \(viewer.intent.rawValue), vibes: \(viewerVibes))
            Person B: \(target.displayName) (intent: \(target.intent.rawValue), vibes: \(targetVibes))

            Last messages (oldest → newest):
            \(messagesSection)
            """

        return Output(system: system, user: user)
    }

    static func toneSpecificClause(_ tone: Tone) -> String {
        switch tone {
        case .energetic:   return "The conversation has good energy — match it. Light playful escalation is welcome."
        case .deep:        return "The conversation is thoughtful and longer-form. Match the depth; ask one open follow-up."
        case .meetupReady: return "Both parties seem meetup-ready. Suggest a public-place hangout (coffee, walk, public event) — never request a private location share."
        case .slow:        return "The conversation is slow. Keep suggestions light and easy to answer."
        }
    }
}
