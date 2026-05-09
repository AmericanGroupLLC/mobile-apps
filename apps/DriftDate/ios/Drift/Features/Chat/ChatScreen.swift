import SwiftUI
import DriftCore

struct ChatScreen: View {
    let conversation: Conversation
    @EnvironmentObject private var session: AppSession
    @State private var messages: [Message] = []
    @State private var draft = ""
    @State private var suggestions: ReplySuggestion?

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { m in
                        MessageBubble(message: m, isMine: m.authorId == session.currentProfile?.id)
                    }
                }.padding()
            }
            ReplySuggestionsBar(suggestions: suggestions, onTap: { picked in draft = picked })
            HStack {
                TextField("Message", text: $draft).textFieldStyle(.roundedBorder)
                Button { Task { await send() } } label: { Image(systemName: "paperplane.fill") }
                    .disabled(draft.isEmpty)
            }.padding()
        }
        .navigationTitle("Chat")
        .task {
            messages = (try? await ChatService.shared.messages(in: conversation.id)) ?? []
            suggestions = try? await ReplyService.shared.suggestions(for: conversation.id)
            AnalyticsService.shared.track(.chatScreenOpen(conversationId: conversation.id, tone: conversation.tone))
        }
    }

    private func send() async {
        guard let viewer = session.currentProfile else { return }
        let m = try? await ChatService.shared.send(text: draft, in: conversation.id, authorId: viewer.id)
        if let m { messages.append(m) }
        draft = ""
    }
}
