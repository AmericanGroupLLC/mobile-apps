import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Locale-aware TTS wrapper around `AVSpeechSynthesizer`. Premium-voice
/// access is gated by the entitlement service.
public final class VoiceSynthesizer {

    public var rate: Float = 0.5
    public var pitch: Float = 1.0
    public var volume: Float = 1.0

    public init() {}

    public func speak(_ text: String, language: Language, premium: Bool = false) {
        #if canImport(AVFoundation)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        let voice: AVSpeechSynthesisVoice?
        if premium,
           let enhanced = AVSpeechSynthesisVoice.speechVoices()
            .first(where: { $0.language == language.localeIdentifier && $0.quality == .enhanced }) {
            voice = enhanced
        } else {
            voice = AVSpeechSynthesisVoice(language: language.localeIdentifier)
        }
        utterance.voice = voice
        Self.synth.speak(utterance)
        #endif
    }

    public func stop() {
        #if canImport(AVFoundation)
        Self.synth.stopSpeaking(at: .immediate)
        #endif
    }

    #if canImport(AVFoundation)
    private static let synth = AVSpeechSynthesizer()
    #endif
}
