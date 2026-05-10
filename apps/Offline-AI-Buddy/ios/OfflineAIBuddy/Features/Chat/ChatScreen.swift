import SwiftUI
import BuddyAICore

struct ChatScreen: View {
    let kind: ChatSession.Kind
    @EnvironmentObject private var llama: LlamaService
    @EnvironmentObject private var profilesModel: ProfilesModel
    @EnvironmentObject private var quota: QuotaService
    @EnvironmentObject private var entitlement: EntitlementBootstrap
    @StateObject private var vm = ChatViewModel()
    @State private var input: String = ""
    @State private var language: Language = .en

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { m in
                            ChatBubbleView(message: m)
                        }
                        if !vm.streamingText.isEmpty {
                            ChatBubbleView(message: ChatMessage(role: .assistant, text: vm.streamingText))
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.streamingText) { _, _ in
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
            HStack {
                LanguagePickerView(language: $language)
                Spacer()
                if vm.isStreaming {
                    Text("Generating…").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            ChatInputBar(text: $input, onSend: send)
        }
        .navigationTitle(kind.displayName)
        .onAppear {
            language = profilesModel.defaultLanguage
        }
    }

    private func send() {
        guard let active = profilesModel.activeProfile else { return }
        let pro = entitlement.state.proUnlocked
        guard quota.mayStartChat(for: active.id, proUnlocked: pro).allowed else {
            vm.showQuotaExhausted = true
            return
        }
        let text = input
        input = ""
        vm.append(ChatMessage(role: .user, text: text))
        quota.recordChatStarted(for: active.id, proUnlocked: pro)
        Task {
            let isKid = active.kind == .kidSafe
            let stream = llama.generate(
                kind: kind,
                language: language,
                isKidSafe: isKid,
                history: vm.messages,
                userInput: text
            )
            await vm.consume(stream, isKidSafe: isKid, language: language)
        }
    }
}
