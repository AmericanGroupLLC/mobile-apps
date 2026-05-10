import SwiftUI
import CardCore

/// Voice-first composer. Falls back to standard watchOS dictation TextField
/// when SFSpeechRecognizer is unavailable.
struct ComposerView: View {
    @EnvironmentObject private var repository: WatchCardRepository
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 12) {
            // The watchOS TextField triggers the system dictation/scribble UI
            // automatically when tapped. That IS the voice path on watch.
            TextField("Speak or scribble", text: $text)
                .textFieldStyle(.automatic)
                .font(.body)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    repository.capture(text: text)
                    dismiss()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .navigationTitle("Capture")
    }
}
