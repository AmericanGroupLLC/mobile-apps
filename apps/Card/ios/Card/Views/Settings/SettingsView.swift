import SwiftUI
import CardCore

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsModel
    @EnvironmentObject private var repository: CardRepository
    @Environment(\.dismiss) private var dismiss
    @State private var showEraseConfirm = false

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Use 24-hour time", isOn: $settings.use24Hour)
                Picker("Theme", selection: $settings.themeChoice) {
                    ForEach(ThemeChoice.allCases) { Text($0.label).tag($0) }
                }
            }

            Section {
                Toggle("Send crash reports", isOn: Binding(
                    get: { settings.crashOptedIn },
                    set: { newValue in
                        settings.crashOptedIn = newValue
                        CrashReportingService.shared.optedIn = newValue
                        AnalyticsService.shared.track(
                            .settingsToggled(name: "crash_opt_in", enabled: newValue))
                    }
                ))
                Toggle("Send anonymous usage data", isOn: Binding(
                    get: { settings.analyticsOptedIn },
                    set: { newValue in
                        settings.analyticsOptedIn = newValue
                        AnalyticsService.shared.optedIn = newValue
                        AnalyticsService.shared.track(
                            .settingsToggled(name: "analytics_opt_in", enabled: newValue))
                    }
                ))
            } header: {
                Text("Privacy")
            } footer: {
                Text("Both off by default. Nothing leaves your device unless you flip a toggle.")
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
                Link("github.com/AmericanGroupLLC/Card",
                     destination: URL(string: "https://github.com/AmericanGroupLLC/Card")!)
            }

            Section {
                Button(role: .destructive) {
                    showEraseConfirm = true
                } label: {
                    Text("Erase all data")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog(
            "Delete every Card on this device?",
            isPresented: $showEraseConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase all data", role: .destructive) {
                repository.eraseAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This cannot be undone.")
        }
    }
}
