import SwiftUI
import BuddyCore

struct SettingsScreen: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var rivalries: RivalriesModel
    @State private var showEraseConfirm = false
    @State private var showResetIdConfirm = false

    private let deviceIds = DeviceIdProvider()

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display name", text: $settings.displayName)
                }
                Section("Connectivity") {
                    Picker("Preference", selection: $settings.connectivityPreference) {
                        Text("Auto").tag(ConnectivityBridge.Preference.auto)
                        Text("Wi-Fi only").tag(ConnectivityBridge.Preference.wifiOnly)
                        Text("BLE only").tag(ConnectivityBridge.Preference.bleOnly)
                    }
                }
                Section("Game") {
                    Picker("Default game", selection: Binding(
                        get: { settings.defaultGame },
                        set: { settings.defaultGame = $0 }
                    )) {
                        ForEach(GameKind.allCases, id: \.self) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                }
                Section("Feedback") {
                    Toggle("Sound", isOn: $settings.soundEnabled)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                }
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { settings.theme },
                        set: { settings.theme = $0 }
                    )) {
                        ForEach(SettingsModel.Theme.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }
                Section("Privacy") {
                    HStack {
                        Image(systemName: "lock.shield.fill").foregroundStyle(.green)
                        Text("BuddyPlay does not send any data.")
                            .font(.callout)
                    }
                    Button("Erase all rivalries", role: .destructive) {
                        showEraseConfirm = true
                    }
                    Button("Reset device ID", role: .destructive) {
                        showResetIdConfirm = true
                    }
                }
                Section {
                    Text("BuddyPlay v1.0 · MIT-licensed")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Erase all rivalries?", isPresented: $showEraseConfirm) {
                Button("Erase", role: .destructive) { rivalries.eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This wipes every win/loss tally on this device. There's no cloud backup — this is the only copy.")
            }
            .alert("Reset device ID?", isPresented: $showResetIdConfirm) {
                Button("Reset", role: .destructive) { _ = deviceIds.reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Other phones will see you as a brand-new opponent (rivalries restart).")
            }
        }
    }
}
