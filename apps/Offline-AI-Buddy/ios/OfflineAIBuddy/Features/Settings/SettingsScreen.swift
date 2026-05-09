import SwiftUI
import BuddyAICore

struct SettingsScreen: View {
    @EnvironmentObject private var profilesModel: ProfilesModel
    @EnvironmentObject private var llama: LlamaService
    @AppStorage("settings.wifionly") private var wifiOnlyDownload: Bool = true
    @AppStorage("settings.tts.speed") private var ttsSpeed: Double = 0.5
    @AppStorage("settings.theme") private var theme: String = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Default language", selection: $profilesModel.defaultLanguage) {
                        ForEach(Language.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }
                Section("Voice") {
                    HStack { Text("TTS speed"); Slider(value: $ttsSpeed, in: 0.2...1.0) }
                }
                Section("Connectivity") {
                    Toggle("Wi-Fi-only model downloads", isOn: $wifiOnlyDownload)
                }
                Section("Appearance") {
                    Picker("Theme", selection: $theme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Premium") {
                    NavigationLink("Subscribe / Restore") { SubscriptionScreen() }
                }
                Section("Storage") {
                    Button("Erase all chats", role: .destructive) {
                        try? ChatHistoryStore().eraseAll()
                    }
                    Button("Delete model", role: .destructive) {
                        try? llama.store.remove(named: "\(llama.manifest.name).gguf")
                    }
                }
                Section("Privacy") {
                    Text("Offline AI Buddy does not send any data to us.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
