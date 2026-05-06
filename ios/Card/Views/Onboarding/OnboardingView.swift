import SwiftUI
import CardCore

struct OnboardingView: View {
    @EnvironmentObject private var settings: SettingsModel
    @State private var pageIndex: Int = 0

    var body: some View {
        TabView(selection: $pageIndex) {
            page1.tag(0)
            page2.tag(1)
            page3.tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Card")
                .font(.system(size: 56, weight: .bold))
            Text("Nothing you write gets forgotten or ignored.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Continue") { pageIndex = 1 }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 64)
        }
    }

    private var page2: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Reminders need notification permission")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Card uses your device's notification stack so reminders fire even when the app is closed.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Allow notifications") {
                ReminderService.shared.requestAuthorization()
                pageIndex = 2
            }
            .buttonStyle(.borderedProminent)
            Button("Skip for now") { pageIndex = 2 }
                .padding(.bottom, 64)
        }
    }

    private var page3: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("You're set.")
                .font(.title2.bold())
            Text("Type, tap, save. The rest disappears.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Open Card") {
                AnalyticsService.shared.track(.onboardingCompleted)
                settings.onboardingCompleted = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 64)
        }
    }
}
