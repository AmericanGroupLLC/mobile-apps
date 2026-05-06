import SwiftUI

/// We do NOT prompt for mic / speech permissions here — they're
/// requested on first push-to-talk use. This screen is just a
/// "you're all set" landing page that the OnboardingFlow ends on.
struct PermissionsScreen: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 64)).foregroundStyle(.green)
            Text("You're set up").font(.title2).bold()
            Text("We'll ask for microphone access only when you tap the voice button.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
            Spacer()
        }
        .padding()
    }
}
