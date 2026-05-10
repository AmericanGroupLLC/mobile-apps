import SwiftUI

/// Top-level navigation. v1 is a single tab bar between Home, Rivalries,
/// and Settings — Lobby + Game screens are pushed modally from Home.
struct RootView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }
            RivalriesScreen()
                .tabItem { Label("Rivalries", systemImage: "trophy.fill") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
