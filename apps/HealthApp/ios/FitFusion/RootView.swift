import SwiftUI
import FitFusionCore

struct RootView: View {
    @EnvironmentObject var auth: AuthStore
    @AppStorage(AuthStore.didOnboardKey) private var didOnboard: Bool = false

    var body: some View {
        Group {
            if !auth.isAuthenticated {
                LoginView()
            } else if !didOnboard {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
    }
}
