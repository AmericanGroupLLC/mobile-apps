import Foundation
import BuddyAICore

/// App-side voice service. Wraps `BuddyAICore.VoiceSynthesizer` +
/// `VoiceRecognizer` for SwiftUI callers.
@MainActor
final class VoiceService: ObservableObject {

    @Published var isListening: Bool = false
    @Published var partialTranscript: String = ""

    private let synth = VoiceSynthesizer()
    private let recognizer = VoiceRecognizer()
    private var listeningTask: Task<Void, Never>?

    func speak(_ text: String, language: Language, premium: Bool) {
        synth.speak(text, language: language, premium: premium)
    }

    func stopSpeaking() {
        synth.stop()
    }

    func startListening(language: Language, onFinal: @escaping (String) -> Void) {
        isListening = true
        partialTranscript = ""
        let stream = recognizer.start(language: language)
        listeningTask = Task { [weak self] in
            for await t in stream {
                await MainActor.run { self?.partialTranscript = t }
            }
            await MainActor.run {
                self?.isListening = false
                onFinal(self?.partialTranscript ?? "")
            }
        }
    }

    func stopListening() {
        recognizer.stop()
        listeningTask?.cancel()
        listeningTask = nil
        isListening = false
    }
}
