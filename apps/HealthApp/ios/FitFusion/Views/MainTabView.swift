import SwiftUI
import FitFusionCore

/// Care+ root tab bar. Four tabs: Care · Diet · Train · Workout.
/// Former 5-tab layout (Home/Train/Diary/Sleep/More) is consolidated:
///   • Home dashboard tiles  →  surfaced inside Care home + Workout home
///   • Train                 →  unchanged (now the Train tab proper)
///   • Diary                 →  rebranded as Diet tab home
///   • Sleep                 →  surfaced inside Workout tab
///   • More                  →  reachable via header avatar (Profile) and
///                              header bell (News drawer) on every tab
struct MainTabView: View {
    var body: some View {
        TabView {
            CareHomeView()
                .tabItem { Label("Care", systemImage: CarePlusTab.care.symbol) }

            DietHomeView()
                .tabItem { Label("Diet", systemImage: CarePlusTab.diet.symbol) }

            TrainHomeView()
                .tabItem { Label("Train", systemImage: CarePlusTab.train.symbol) }

            WorkoutHomeView()
                .tabItem { Label("Workout", systemImage: CarePlusTab.workout.symbol) }
        }
        .tint(CarePlusPalette.careBlue)
    }
}
