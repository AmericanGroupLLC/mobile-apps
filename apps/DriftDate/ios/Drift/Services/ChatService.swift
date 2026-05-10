import Foundation
import DriftCore

/// Sends + lists messages, plus a Realtime subscription stub.
final class ChatService {
    static let shared = ChatService()

    func conversations() async throws -> [Conversation] {
        guard let client = SupabaseClient.shared else { return [] }
        return (try? await client.get("rest/v1/conversations", query: ["select": "*"])) ?? []
    }

    func messages(in conversationId: UUID) async throws -> [Message] {
        guard let client = SupabaseClient.shared else { return [] }
        return (try? await client.get(
            "rest/v1/messages",
            query: ["select": "*",
                    "conversation_id": "eq.\(conversationId.uuidString)",
                    "order": "created_at.asc",
                    "limit": "200"]
        )) ?? []
    }

    func send(text: String, in conversationId: UUID, authorId: UUID) async throws -> Message {
        guard let client = SupabaseClient.shared else { throw ChatError.noClient }
        let m = Message(conversationId: conversationId, authorId: authorId, text: text)
        let _: EmptyResponse = try await client.post("rest/v1/messages", body: m)
        return m
    }

    enum ChatError: Error { case noClient }
}
