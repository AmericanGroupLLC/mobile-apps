import SwiftUI

/// Three-step onboarding flow: Consent → Profile setup → Model
/// download → (Permissions are deferred to first-use, NOT shown here).
struct OnboardingFlow: View {
    @State private var step: Step = .consent

    enum Step { case consent, profile, download, done }

    var body: some View {
        switch step {
        case .consent:
            ConsentScreen { step = .profile }
        case .profile:
            ProfileSetupScreen { step = .download }
        case .download:
            ModelDownloadScreen { step = .done }
        case .done:
            PermissionsScreen()
        }
    }
}
