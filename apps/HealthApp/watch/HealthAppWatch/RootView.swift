import SwiftUI
import FitFusionCore

struct RootView: View {
    @EnvironmentObject var auth: AuthStore

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabsView()
            } else {
                LoginView()
            }
        }
    }
}
