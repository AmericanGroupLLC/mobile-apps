import SwiftUI
import FitFusionCore

/// Settings screen — covers Guest mode <-> account toggle, theme, units,
/// language, data export/erase, API base URL, and app info.
struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore
    @AppStorage("apiBaseURL") private var apiBaseURL: String = "http://localhost:4000"
    @AppStorage("themeMode") private var themeMode: String = "system"   // system / light / dark
    @AppStorage("language") private var language: String = "en"
    @AppStorage("unitsImperial") private var unitsImperial: Bool = false

    @State private var showSignIn = false
    @State private var exportURL: URL?
    @State private var showExportShare = false
    @State private var confirmErase = false

    var body: some View {
        Form {
            Section("Account") {
                if auth.isGuest {
                    Label("Guest mode", systemImage: "person.crop.circle.badge.checkmark")
                        .foregroundStyle(.indigo)
                    Button {
                        showSignIn = true
                    } label: {
                        Label("Sign in for cloud sync", systemImage: "icloud.and.arrow.up.fill")
                    }
                } else if let u = auth.user {
                    Label(u.name, systemImage: "person.crop.circle.fill")
                    Text(u.email).font(.caption2).foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        auth.logout()
                    } label: { Label("Log out", systemImage: "rectangle.portrait.and.arrow.right") }
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $themeMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                Toggle("Imperial units (ft/lb)", isOn: $unitsImperial)
                Picker("Language", selection: $language) {
                    Text("English").tag("en")
                    Text("Espa\u{00f1}ol").tag("es")
                    Text("Fran\u{00e7}ais").tag("fr")
                    Text("Deutsch").tag("de")
                    Text("\u{0939}\u{093f}\u{0928}\u{094d}\u{0926}\u{0940}").tag("hi")
                }
            }

            Section("Backend (optional)") {
                TextField("API base URL", text: $apiBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("Only used for sync if you have an account. Guest mode never contacts the network for personal data.")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Section("Privacy") {
                Toggle(isOn: Binding(
                    get: { CrashReportingService.shared.isEnabled },
                    set: { CrashReportingService.shared.setEnabled($0) }
                )) {
                    Label("Send crash reports", systemImage: "ant.fill")
                }
                Text("Off by default. When on, anonymous crash stack traces (no personal data) are sent to Sentry to help fix bugs. You can turn this off any time.")
                    .font(.caption2).foregroundStyle(.secondary)

                Toggle(isOn: Binding(
                    get: { AnalyticsService.shared.isEnabled },
                    set: { AnalyticsService.shared.setEnabled($0) }
                )) {
                    Label("Share anonymous usage analytics", systemImage: "chart.bar.fill")
                }
                Text("Off by default. When on, only anonymous feature-usage events (e.g. \u{201C}meal logged\u{201D}) are sent to PostHog so we can see which features are used. No personal data, no health metrics, no contents of meals/medicines/mood entries are ever included.")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Section("Data") {
                Button {
                    do {
                        exportURL = try PortabilityService.shared.exportEverything()
                        showExportShare = true
                    } catch {
                        // best-effort UI
                    }
                } label: {
                    Label("Export my data (JSON)", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    confirmErase = true
                } label: {
                    Label("Erase all on-device data", systemImage: "trash.fill")
                }
            }

            Section("About") {
                LabeledContent("App", value: "MyHealth")
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
                LabeledContent("Mode", value: auth.isGuest ? "Guest (local-only)" : "Cloud-synced")
                Link("Privacy",
                     destination: URL(string: "https://example.com/privacy")!)
                Link("Open Food Facts",
                     destination: URL(string: "https://world.openfoodfacts.org")!)
                Link("MyHealthfinder (health.gov)",
                     destination: URL(string: "https://health.gov/myhealthfinder")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSignIn) {
            NavigationStack { LoginView() }
        }
        .sheet(isPresented: $showExportShare) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
        .alert("Erase everything?", isPresented: $confirmErase) {
            Button("Cancel", role: .cancel) {}
            Button("Erase", role: .destructive) {
                PortabilityService.shared.eraseAllLocalData()
            }
        } message: {
            Text("All meals, exercise logs, medicines, profile, mood, and challenges on this device will be deleted. This cannot be undone.")
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
