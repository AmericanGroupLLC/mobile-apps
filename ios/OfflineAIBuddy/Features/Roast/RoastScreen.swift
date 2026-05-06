import SwiftUI
import BuddyAICore

struct RoastScreen: View {
    @StateObject private var vm = ChatViewModel()
    @EnvironmentObject private var llama: LlamaService
    @EnvironmentObject private var profilesModel: ProfilesModel
    @State private var input: String = "I drink coffee every 30 minutes"

    var body: some View {
        VStack {
            ScrollView {
                ForEach(vm.messages) { ChatBubbleView(message: $0) }
                if !vm.streamingText.isEmpty {
                    ChatBubbleView(message: ChatMessage(role: .assistant, text: vm.streamingText))
                }
            }
            ChatInputBar(text: $input) { roastMe() }
        }
        .navigationTitle("Roast Mode")
    }

    private func roastMe() {
        guard let p = profilesModel.activeProfile else { return }
        let text = input
        input = ""
        vm.append(ChatMessage(role: .user, text: text))
        Task {
            let stream = llama.generate(
                kind: .roast,
                language: profilesModel.defaultLanguage,
                isKidSafe: p.kind == .kidSafe,
                history: vm.messages,
                userInput: text
            )
            await vm.consume(stream, isKidSafe: p.kind == .kidSafe, language: profilesModel.defaultLanguage)
        }
    }
}
