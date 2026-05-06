import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ClockView()
                .tabItem { Label("Clock", systemImage: "clock") }

            AlarmView()
                .tabItem { Label("Alarm", systemImage: "alarm") }

            StopwatchView()
                .tabItem { Label("Stopwatch", systemImage: "stopwatch") }

            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
        }
    }
}

#Preview {
    ContentView()
}
