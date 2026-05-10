import SwiftUI
import FitFusionCore

@main
struct HealthAppWatchApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var hk = HealthKitManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(hk)
                .tint(.cyan)
                .task {
                    if auth.isAuthenticated {
                        await hk.requestAuthorization()
                    }
                }
        }
    }
}
