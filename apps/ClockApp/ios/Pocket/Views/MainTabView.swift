import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ToolsLauncherView()
                .tabItem { Label("Tools", systemImage: "square.grid.2x2") }
            NavigationStack { ClockHomeView() }
                .tabItem { Label("Clock", systemImage: "clock") }
            NavigationStack { CalculatorView() }
                .tabItem { Label("Calculator", systemImage: "function") }
            NavigationStack { CompassView() }
                .tabItem { Label("Compass", systemImage: "location.north.line") }
            NavigationStack { LevelView() }
                .tabItem { Label("Level", systemImage: "ruler") }
        }
    }
}

/// Wraps the existing AlarmView/ClockView/etc with a simple home + nav.
struct ClockHomeView: View {
    var body: some View {
        List {
            NavigationLink("World Clock", destination: ClockView())
            NavigationLink("Alarms",      destination: AlarmView())
            NavigationLink("Stopwatch",   destination: StopwatchView())
            NavigationLink("Timer",       destination: TimerView())
            NavigationLink("Bedtime",     destination: BedtimeView())
            NavigationLink("Settings",    destination: SettingsView())
        }
        .navigationTitle("Clock")
    }
}
