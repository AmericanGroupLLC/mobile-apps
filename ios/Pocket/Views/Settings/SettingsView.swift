import SwiftUI
import PocketCore

struct SettingsView: View {
    @AppStorage("use24Hour")        private var use24Hour: Bool = false
    @AppStorage("measureUnitCm")    private var measureUnitCm: Bool = true
    @AppStorage("useTrueHeading")   private var useTrueHeading: Bool = true
    @AppStorage("crashReportingOptIn") private var crashOptIn: Bool = false
    @AppStorage("analyticsOptIn")      private var analyticsOptIn: Bool = false

    var body: some View {
        Form {
            Section("Clock") {
                Toggle("24-hour time", isOn: $use24Hour)
            }
            Section("Measure") {
                Picker("Unit", selection: $measureUnitCm) {
                    Text("cm").tag(true)
                    Text("inches").tag(false)
                }
                .pickerStyle(.segmented)
            }
            Section("Compass") {
                Toggle("True heading", isOn: $useTrueHeading)
            }
            Section("Privacy") {
                Toggle("Send crash reports (Sentry)", isOn: $crashOptIn)
                    .onChange(of: crashOptIn) { CrashReportingService.shared.optedIn = $0 }
                Toggle("Send anonymous analytics (PostHog)", isOn: $analyticsOptIn)
                    .onChange(of: analyticsOptIn) { AnalyticsService.shared.optedIn = $0 }
                Button("Erase all data", role: .destructive, action: eraseAll)
            }
            Section("About") {
                Text("Pocket — five tools that disappear into the OS.")
                    .font(.footnote).foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private func eraseAll() {
        let dom = Bundle.main.bundleIdentifier ?? "com.americangroupllc.pocket"
        UserDefaults.standard.removePersistentDomain(forName: dom)
    }
}
