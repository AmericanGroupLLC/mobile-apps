import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ClockView()
            StopwatchView()
            TimerView()
        }
        .tabViewStyle(.page)
    }
}

#Preview { ContentView() }
