import SwiftUI
import CardCore

/// Onboarding gate → main feed.
struct RootView: View {
    @EnvironmentObject private var settings: SettingsModel
    @State private var showSettings = false

    var body: some View {
        Group {
            if settings.onboardingCompleted {
                NavigationStack {
                    FeedView()
                        .navigationTitle("Card")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button { showSettings = true } label: {
                                    Image(systemName: "gearshape")
                                }
                                .accessibilityLabel("Settings")
                            }
                        }
                        .sheet(isPresented: $showSettings) {
                            NavigationStack { SettingsView() }
                        }
                }
            } else {
                OnboardingView()
            }
        }
    }
}
