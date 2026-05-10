import SwiftUI
import DriftCore

struct SettingsScreen: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var settings: SettingsModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Discoverability") {
                    Toggle("Invisible", isOn: $settings.invisible)
                    Toggle("Pause discoverability", isOn: $settings.paused)
                }
                Section("Telemetry") {
                    Toggle("Send crash reports", isOn: $settings.crashOptedIn)
                    Toggle("Send anonymous analytics", isOn: $settings.analyticsOptedIn)
                }
                Section("Display") {
                    Toggle("12-hour clock", isOn: $settings.preferred12HourClock)
                    Picker("Theme", selection: $settings.theme) {
                        Text("System").tag(SettingsModel.AppTheme.system)
                        Text("Light").tag(SettingsModel.AppTheme.light)
                        Text("Dark").tag(SettingsModel.AppTheme.dark)
                    }
                }
                Section("Safety") {
                    NavigationLink("Blocked users") { BlockedUsersScreen() }
                }
                Section("Account") {
                    Button("Erase all data", role: .destructive) { /* DELETE /functions/v1/wipe-me */ }
                    Button("Delete account",  role: .destructive) { Task { await session.signOut() } }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
