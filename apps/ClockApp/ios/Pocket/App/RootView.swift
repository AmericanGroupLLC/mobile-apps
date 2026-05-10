import SwiftUI

struct RootView: View {
    @Binding var onboardingComplete: Bool
    var body: some View {
        if onboardingComplete {
            MainTabView()
        } else {
            OnboardingView(onComplete: { onboardingComplete = true })
        }
    }
}
