import SwiftUI
import AVFoundation
import DriftCore

/// 30-second voice prompt recorder (skeleton — wires up AVAudioRecorder
/// only when permissions are granted on a real device).
struct VoicePromptRecorder: View {
    @State private var isRecording = false
    @State private var elapsed: Double = 0

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundStyle(isRecording ? .red : .accentColor)
                Text(isRecording ? "Recording — \(Int(elapsed))s" : "Tap to record (max 30s)")
            }
            .contentShape(Rectangle())
            .onTapGesture { isRecording.toggle() }
        }
    }
}
