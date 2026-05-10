import SwiftUI
import BuddyAICore

struct ChatBubbleView: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            Text(message.text)
                .padding(10)
                .background(message.role == .user ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if message.role != .user { Spacer() }
        }
    }
}

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            TextField("Type a message…", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }
}

struct LanguagePickerView: View {
    @Binding var language: Language
    var body: some View {
        Menu {
            ForEach(Language.allCases, id: \.self) { l in
                Button(l.displayName) { language = l }
            }
        } label: {
            Label(language.displayName, systemImage: "globe")
                .font(.footnote)
        }
    }
}
