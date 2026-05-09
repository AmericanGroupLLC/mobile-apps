import SwiftUI
import BuddyAICore

struct PartyQuestionsScreen: View {
    @EnvironmentObject private var llama: LlamaService
    @EnvironmentObject private var profilesModel: ProfilesModel
    @State private var audience: String = "friends"
    @State private var questions: String = ""
    @State private var loading = false

    var body: some View {
        VStack(spacing: 16) {
            Picker("Audience", selection: $audience) {
                Text("Work").tag("work")
                Text("Friends").tag("friends")
                Text("First date").tag("first-date")
                Text("Family").tag("family")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                Text(questions.isEmpty ? "Tap below to get 5 ice-breakers." : questions)
                    .padding()
            }
            Button("Generate 5 questions") { Task { await fetch() } }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Party Questions")
    }

    private func fetch() async {
        loading = true
        defer { loading = false }
        let isKid = profilesModel.activeProfile?.kind == .kidSafe
        let stream = llama.generate(
            kind: .partyQuestions,
            language: profilesModel.defaultLanguage,
            isKidSafe: isKid,
            history: [],
            userInput: audience
        )
        var collected = ""
        for await t in stream { collected += t.text; if t.isLast { break } }
        questions = collected.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
