import SwiftUI
import FitFusionCore

struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore
    @EnvironmentObject var hk: HealthKitManager
    @State private var apiURL: String = APIConfig.baseURL
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Settings").font(.headline).foregroundStyle(.white)

                if let u = auth.user {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(u.name).font(.caption).bold().foregroundStyle(.white)
                        Text(u.email).font(.system(size: 10)).foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }

                // HealthKit
                VStack(alignment: .leading, spacing: 4) {
                    Label(hk.isAuthorized ? "HealthKit ON" : "HealthKit OFF",
                          systemImage: hk.isAuthorized ? "heart.text.square.fill" : "heart.slash")
                        .font(.caption2).foregroundStyle(.white)
                    if let s = hk.lastSyncSummary {
                        Text(s).font(.system(size: 10)).foregroundStyle(.white.opacity(0.8))
                    }
                    Button(hk.isAuthorized ? "Sync Now" : "Connect HealthKit") {
                        Task {
                            if hk.isAuthorized { hk.startObservers() }
                            else { await hk.requestAuthorization() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(8)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("API URL").font(.caption2).foregroundStyle(.white.opacity(0.8))
                    TextField("http://...", text: $apiURL)
                    Button("Save URL") {
                        UserDefaults.standard.set(apiURL, forKey: "apiBaseURL")
                        saved = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    if saved {
                        Text("✓ Saved").font(.caption2).foregroundStyle(.green)
                    }
                }

                Button(role: .destructive) {
                    auth.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 4)
            }
            .padding(8)
        }
    }
}
