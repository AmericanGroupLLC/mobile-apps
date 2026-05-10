import SwiftUI
import PocketCore

@main
struct PocketApp: App {
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false

    var body: some Scene {
        WindowGroup {
            RootView(onboardingComplete: $onboardingComplete)
        }
    }
}
