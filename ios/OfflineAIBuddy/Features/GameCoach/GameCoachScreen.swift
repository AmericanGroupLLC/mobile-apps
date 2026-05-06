import SwiftUI
import BuddyAICore

struct GameCoachScreen: View {
    @StateObject private var vm = ChatViewModel()
    @EnvironmentObject private var llama: LlamaService
    @EnvironmentObject private var profilesModel: ProfilesModel
    @State private var game: String = "chess"
    @State private var input: String = ""

    var body: some View {
        VStack {
            Picker("Game", selection: $game) {
                Text("Chess").tag("chess")
                Text("Codenames").tag("codenames")
                Text("Catan").tag("catan")
                Text("Other").tag("other")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                ForEach(vm.messages) { ChatBubbleView(message: $0) }
                if !vm.streamingText.isEmpty {
                    ChatBubbleView(message: ChatMessage(role: .assistant, text: vm.streamingText))
                }
            }
            ChatInputBar(text: $input) { send() }
        }
        .navigationTitle("Game Coach")
    }

    private func send() {
        let text = input
        input = ""
        vm.append(ChatMessage(role: .user, text: "[\(game)] \(text)"))
        Task {
            let stream = llama.generate(
                kind: .gameCoach,
                language: profilesModel.defaultLanguage,
                isKidSafe: profilesModel.activeProfile?.kind == .kidSafe,
                history: vm.messages,
                userInput: "[\(game)] \(text)"
            )
            await vm.consume(stream, isKidSafe: profilesModel.activeProfile?.kind == .kidSafe, language: profilesModel.defaultLanguage)
        }
    }
}
