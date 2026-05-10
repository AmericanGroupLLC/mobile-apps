import SwiftUI

/// Explicitly lists the 3 v1 limitations BEFORE the model download
/// starts. Required for App Review (see STORE-PACKAGING.md §6).
struct ConsentScreen: View {
    let onContinue: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Welcome to Offline AI Buddy").font(.largeTitle).bold()
            Text("Before we start, three things to know:").font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                Bullet(text: "On first launch, we'll download a ~1 GB language model over Wi-Fi. This is the only network step.")
                Bullet(text: "It's a 1.5-billion-parameter model. It can't match cloud GPT-4 on hard reasoning tasks.")
                Bullet(text: "Generation may be slow on older phones (sub-iPhone 14). We'll warn you if your device is below the recommended floor.")
            }
            Spacer()
            Button(action: onContinue) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct Bullet: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "circle.fill").font(.system(size: 6)).padding(.top, 8)
            Text(text)
        }
    }
}
