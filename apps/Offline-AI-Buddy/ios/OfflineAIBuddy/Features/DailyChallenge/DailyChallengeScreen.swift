import SwiftUI
import BuddyAICore

struct DailyChallengeScreen: View {
    @EnvironmentObject private var llama: LlamaService
    @EnvironmentObject private var profilesModel: ProfilesModel
    @State private var challenge: String = ""
    @State private var loading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Today's Challenge").font(.title).bold()
            if loading {
                ProgressView()
            } else {
                Text(challenge.isEmpty ? "Tap below for today's prompt." : challenge)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Button("Generate") {
                Task { await fetch() }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .navigationTitle("Daily Challenge")
        .task { if challenge.isEmpty { await fetch() } }
    }

    private func fetch() async {
        loading = true
        defer { loading = false }
        let cacheKey = "dailychallenge.\(QuotaState.dayString(for: Date())).\(profilesModel.defaultLanguage.rawValue)"
        if let cached = UserDefaults.standard.string(forKey: cacheKey) {
            challenge = cached
            return
        }
        let stream = llama.generate(
            kind: .dailyChallenge,
            language: profilesModel.defaultLanguage,
            isKidSafe: profilesModel.activeProfile?.kind == .kidSafe,
            history: [],
            userInput: ""
        )
        var collected = ""
        for await t in stream { collected += t.text; if t.isLast { break } }
        challenge = collected.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(challenge, forKey: cacheKey)
    }
}
