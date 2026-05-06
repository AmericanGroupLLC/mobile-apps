import SwiftUI
import BuddyAICore

struct PinPromptView: View {
    let profile: Profile
    let onSubmit: (String) -> Void
    @State private var pin: String = ""
    @State private var failed: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter PIN for \(profile.name)").font(.headline)
            SecureField("PIN", text: $pin)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding()
            if failed {
                Text("Incorrect PIN").foregroundStyle(.red).font(.footnote)
            }
            Button("Unlock") {
                onSubmit(pin)
                failed = pin.count == 4
                pin = ""
            }
            .buttonStyle(.borderedProminent)
            .disabled(pin.count != 4)
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
}
