import SwiftUI
import FitFusionCore

struct MainTabsView: View {
    var body: some View {
        TabView {
            QuickLogView()
                .containerBackground(.cyan.gradient, for: .tabView)

            LiveWorkoutView()

            RunSessionView()

            AnatomyView()

            WaterLogView()
                .containerBackground(.blue.gradient, for: .tabView)

            WeightLogView()
                .containerBackground(.purple.gradient, for: .tabView)

            MoodLogView()
                .containerBackground(.pink.gradient, for: .tabView)

            HistoryView()
                .containerBackground(.gray.gradient, for: .tabView)

            SettingsView()
                .containerBackground(.indigo.gradient, for: .tabView)
        }
        .tabViewStyle(.verticalPage)
    }
}
