import SwiftUI
import BuddyCore

@main
struct BuddyPlayApp: App {
    @StateObject private var settings = SettingsModel()
    @StateObject private var connectivity = ConnectivityService()
    @StateObject private var rivalries = RivalriesModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(connectivity)
                .environmentObject(rivalries)
                .preferredColorScheme(settings.colorScheme)
        }
    }
}
