import Foundation

/// Pure function: classify the conversation's tone from a sliding window of
/// recent messages. No LLM in the client.
///
/// Heuristics (mirrored case-for-case in Kotlin):
///   * gap > 4h between latest two messages -> .slow
///   * meetup-pattern keyword match          -> .meetupReady
///   * avg message length > 200              -> .deep
///   * 10+ messages in 5 minutes             -> .energetic
///   * else                                  -> .slow
public enum ToneClassifier {
    /// Word patterns that bias the conversation toward `.meetupReady`.
    static let meetupPatterns: [String] = [
        "want to grab", "grab a coffee", "grab coffee", "grab dinner",
        "meet up", "meet for", "coffee?", "drinks this", "lunch sometime",
        "let's do", "what about saturday", "what about sunday",
    ]

    public static func classify(messages: [Message], now: Date = Date()) -> Tone {
        guard !messages.isEmpty else { return .slow }

        let sorted = messages.sorted { $0.createdAt < $1.createdAt }
        let recent = Array(sorted.suffix(10))

        // Slow: long pause before the latest two messages.
        if recent.count >= 2 {
            let gap = recent.last!.createdAt.timeIntervalSince(recent[recent.count - 2].createdAt)
            if gap >= 4 * 60 * 60 { return .slow }
        }

        // Meetup-ready: keyword pattern.
        for m in recent {
            let lower = m.text.lowercased()
            if meetupPatterns.contains(where: { lower.contains($0) }) {
                return .meetupReady
            }
        }

        // Deep: long messages on average.
        let avgLen = Double(recent.map { $0.text.count }.reduce(0, +)) / Double(recent.count)
        if avgLen > 200 { return .deep }

        // Energetic: 10+ messages in 5 minutes.
        if recent.count >= 10 {
            let span = recent.last!.createdAt.timeIntervalSince(recent.first!.createdAt)
            if span <= 5 * 60 { return .energetic }
        }

        return .slow
    }
}
