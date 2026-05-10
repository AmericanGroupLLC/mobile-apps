import SwiftUI
import CardCore

struct SettingsView: View {
    @State private var crashOptedIn = false
    @State private var analyticsOptedIn = false

    var body: some View {
        List {
            Toggle("Crash reports", isOn: $crashOptedIn)
                .onChange(of: crashOptedIn) { _, new in
                    CrashReportingService.shared.optedIn = new
                }
            Toggle("Anonymous usage", isOn: $analyticsOptedIn)
                .onChange(of: analyticsOptedIn) { _, new in
                    AnalyticsService.shared.optedIn = new
                }
            Section("About") {
                Text("Card · v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")")
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
    }
}
