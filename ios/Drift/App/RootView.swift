import SwiftUI
import DriftCore

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            switch session.state {
            case .loading:        ProgressView()
            case .needsOnboarding: OnboardingFlowView()
            case .ready:          MainTabsView()
            }
        }
        .task { await session.bootstrap() }
    }
}

struct MainTabsView: View {
    var body: some View {
        TabView {
            DiscoverScreen()
                .tabItem { Label("Discover", systemImage: "person.2.wave.2") }
            MatchesScreen()
                .tabItem { Label("Matches",  systemImage: "heart") }
            ConversationListScreen()
                .tabItem { Label("Chats",    systemImage: "bubble.left.and.bubble.right") }
            ProfileScreen()
                .tabItem { Label("Profile",  systemImage: "person.crop.circle") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
