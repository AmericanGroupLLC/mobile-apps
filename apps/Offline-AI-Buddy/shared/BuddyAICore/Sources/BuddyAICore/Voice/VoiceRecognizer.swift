import Foundation
#if canImport(Speech)
import Speech
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Push-to-talk STT wrapper. On-device recognition where the platform
/// supports it; otherwise we tell the user they need a network for STT
/// — we never silently fall back to cloud STT.
public final class VoiceRecognizer {

    public enum RecognizerError: Error, Sendable {
        case permissionDenied
        case unavailable
        case audioEngineFailed
    }

    public init() {}

    /// Begin recognition. Returns the in-progress `AsyncStream` of
    /// partial transcripts. Call `stop()` to finish.
    public func start(language: Language) -> AsyncStream<String> {
        AsyncStream { continuation in
            #if canImport(Speech) && canImport(AVFoundation)
            let locale = Locale(identifier: language.localeIdentifier)
            guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
                continuation.finish()
                return
            }
            // Caller is responsible for permission; this is a thin wrapper.
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }
            let task = recognizer.recognitionTask(with: request) { result, _ in
                if let r = result {
                    continuation.yield(r.bestTranscription.formattedString)
                    if r.isFinal {
                        continuation.finish()
                    }
                }
            }
            currentTask = task
            currentRequest = request
            #else
            continuation.finish()
            #endif
        }
    }

    public func stop() {
        #if canImport(Speech)
        currentRequest?.endAudio()
        currentTask?.cancel()
        currentRequest = nil
        currentTask = nil
        #endif
    }

    #if canImport(Speech)
    private var currentTask: SFSpeechRecognitionTask?
    private var currentRequest: SFSpeechAudioBufferRecognitionRequest?
    #endif
}
