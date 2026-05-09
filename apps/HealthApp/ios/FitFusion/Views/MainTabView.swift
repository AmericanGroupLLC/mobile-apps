import SwiftUI
import FitFusionCore

/// Restructured 6-tab + More layout. The 5 primary surfaces always visible,
/// the rest live behind a More tab so we don't blow past iOS's tab-bar
/// affordances (anything beyond 5 collapses into "More" automatically).
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            TrainView()
                .tabItem { Label("Train", systemImage: "figure.strengthtraining.traditional") }

            FoodDiaryView()
                .tabItem { Label("Diary", systemImage: "book.closed.fill") }

            SleepRecoveryView()
                .tabItem { Label("Sleep", systemImage: "moon.stars.fill") }

            MoreView()
                .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
        }
    }
}
