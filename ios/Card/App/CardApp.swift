import SwiftUI
import CardCore

@main
struct CardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var repository = CardRepository.shared
    @StateObject private var settings = SettingsModel.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(repository)
                .environmentObject(settings)
                .preferredColorScheme(settings.colorScheme)
        }
    }
}
