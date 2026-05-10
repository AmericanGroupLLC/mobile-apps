import SwiftUI
import DriftCore

struct ConversationListScreen: View {
    @State private var conversations: [Conversation] = []

    var body: some View {
        NavigationStack {
            List(conversations) { c in
                NavigationLink(value: c) {
                    HStack {
                        Image(systemName: "bubble.left.fill").foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text("Conversation").font(.body)
                            Text(c.tone.rawValue).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationDestination(for: Conversation.self) { ChatScreen(conversation: $0) }
            .navigationTitle("Chats")
            .task { conversations = (try? await ChatService.shared.conversations()) ?? [] }
        }
    }
}
