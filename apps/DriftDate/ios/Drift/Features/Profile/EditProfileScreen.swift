import SwiftUI
import DriftCore

struct EditProfileScreen: View {
    @EnvironmentObject private var session: AppSession
    @State private var displayName = ""
    @State private var intent: Intent = .dating

    var body: some View {
        Form {
            TextField("Display name", text: $displayName)
            Picker("Intent", selection: $intent) {
                ForEach(Intent.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            Section("Photos") { PhotoGridEditor() }
            Section("Voice prompt") { VoicePromptRecorder() }
            Section { Button("Save") { Task { await save() } } }
        }
        .navigationTitle("Edit")
        .task {
            displayName = session.currentProfile?.displayName ?? ""
            intent      = session.currentProfile?.intent ?? .dating
        }
    }

    private func save() async {
        guard var p = session.currentProfile else { return }
        p.displayName = displayName
        p.intent = intent
        try? await ProfileService.shared.upsert(p)
    }
}
