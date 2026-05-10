import SwiftUI
import BuddyAICore

struct VoicePushToTalkButton: View {
    @EnvironmentObject private var voice: VoiceService
    let language: Language
    var onTranscript: (String) -> Void

    var body: some View {
        Button {
            if voice.isListening {
                voice.stopListening()
            } else {
                voice.startListening(language: language) { final in
                    onTranscript(final)
                }
            }
        } label: {
            Image(systemName: voice.isListening ? "mic.fill" : "mic")
                .font(.title2)
                .padding(10)
                .background(voice.isListening ? Color.red.opacity(0.2) : Color(.secondarySystemBackground))
                .clipShape(Circle())
        }
    }
}

struct VoicePlaybackButton: View {
    @EnvironmentObject private var voice: VoiceService
    @EnvironmentObject private var entitlement: EntitlementBootstrap
    let text: String
    let language: Language

    var body: some View {
        Button {
            voice.speak(text, language: language, premium: entitlement.state.proUnlocked)
        } label: {
            Image(systemName: "speaker.wave.2.fill").font(.footnote)
        }
        .buttonStyle(.borderless)
    }
}
