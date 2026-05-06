import Foundation
import DriftCore

/// Calls the `reply-suggest` Edge Function.
final class ReplyService {
    static let shared = ReplyService()

    private struct Body: Encodable { let conversation_id: String }

    func suggestions(for conversationId: UUID) async throws -> ReplySuggestion {
        guard let client = SupabaseClient.shared else { throw ReplyError.noClient }
        let body = Body(conversation_id: conversationId.uuidString)
        return try await client.invokeFunction("reply-suggest", body: body, as: ReplySuggestion.self)
    }

    enum ReplyError: Error { case noClient }
}
