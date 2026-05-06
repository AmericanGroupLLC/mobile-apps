import SwiftUI
import BuddyAICore

/// Top-level navigation. If onboarding hasn't completed (no profile +
/// no model on disk) we surface the OnboardingFlow first.
struct RootView: View {

    @EnvironmentObject private var profilesModel: ProfilesModel
    @EnvironmentObject private var llama: LlamaService

    var body: some View {
        Group {
            if profilesModel.profiles.isEmpty {
                OnboardingFlow()
            } else {
                HomeTabs()
            }
        }
        .task {
            await llama.warmupIfModelPresent()
        }
    }
}

private struct HomeTabs: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "sparkles") }
            ProfileSwitcherView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

/// Six-tile launcher. Each tile pushes a feature screen.
struct HomeScreen: View {

    @EnvironmentObject private var profilesModel: ProfilesModel

    private var availableModes: [ChatSession.Kind] {
        let isKid = profilesModel.activeProfile?.kind == .kidSafe
        return ChatSession.Kind.allCases.filter { !isKid || $0.availableInKidSafe }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(availableModes, id: \.self) { kind in
                        NavigationLink(value: kind) {
                            ModeTile(kind: kind)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Offline AI Buddy")
            .navigationDestination(for: ChatSession.Kind.self) { kind in
                switch kind {
                case .chat:           ChatScreen(kind: .chat)
                case .roast:          RoastScreen()
                case .dailyChallenge: DailyChallengeScreen()
                case .partyQuestions: PartyQuestionsScreen()
                case .gameCoach:      GameCoachScreen()
                case .translate:      TranslateScreen()
                }
            }
        }
    }
}

private struct ModeTile: View {
    let kind: ChatSession.Kind
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36))
            Text(kind.displayName).font(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private var icon: String {
        switch kind {
        case .chat:           return "bubble.left.and.bubble.right"
        case .roast:          return "flame"
        case .dailyChallenge: return "calendar.badge.clock"
        case .partyQuestions: return "party.popper"
        case .gameCoach:      return "puzzlepiece.extension"
        case .translate:      return "character.book.closed"
        }
    }
}
