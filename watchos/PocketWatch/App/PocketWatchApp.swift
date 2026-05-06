import SwiftUI
import PocketCore

@main
struct PocketWatchApp: App {
    var body: some Scene {
        WindowGroup { MainPagesView() }
    }
}

struct MainPagesView: View {
    var body: some View {
        TabView {
            WatchClockView().tag(0)
            WatchCalculatorView().tag(1)
            WatchCompassView().tag(2)
            WatchLevelView().tag(3)
            WatchSettingsView().tag(4)
        }
        .tabViewStyle(.page)
    }
}

struct WatchClockView: View {
    @State private var now = Date()
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            VStack(spacing: 8) {
                Text(ctx.date, format: .dateTime.hour().minute().second())
                    .font(.largeTitle.monospacedDigit())
                Text(ctx.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.caption)
            }
        }
    }
}

struct WatchCalculatorView: View {
    @StateObject private var state = CalculatorState()
    private let keys: [[String]] = [
        ["7","8","9","÷"],
        ["4","5","6","×"],
        ["1","2","3","-"],
        ["0",".","=","+"]
    ]
    var body: some View {
        VStack(spacing: 4) {
            Text(state.display).font(.title3.monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .trailing)
            ForEach(keys.indices, id: \.self) { r in
                HStack(spacing: 4) {
                    ForEach(keys[r], id: \.self) { k in
                        Button(k) {
                            if k == "=" { state.equals() } else { state.append(k) }
                        }
                    }
                }
            }
            Button("AC") { state.clear() }.foregroundColor(.red)
        }
        .padding(.horizontal, 4)
    }
}

struct WatchCompassView: View {
    @StateObject private var heading = WatchHeadingService()
    var body: some View {
        VStack {
            Text(HeadingMath.cardinalLabel(forDegrees: heading.magneticHeading))
                .font(.largeTitle).bold()
            Text(String(format: "%.0f°", heading.magneticHeading))
                .font(.title3.monospacedDigit())
            Image(systemName: "location.north.fill")
                .font(.system(size: 40)).foregroundColor(.red)
                .rotationEffect(.degrees(-heading.magneticHeading))
        }
        .onAppear { heading.start() }
        .onDisappear { heading.stop() }
    }
}

struct WatchLevelView: View {
    @StateObject private var att = WatchAttitudeService()
    var body: some View {
        let pr = att.pitchRoll
        ZStack {
            Circle().stroke(.secondary, lineWidth: 1).frame(width: 120, height: 120)
            let off = LevelMath.bubbleOffset(forPitch: pr.pitchDegrees, roll: pr.rollDegrees, radius: 60)
            Circle().fill(abs(pr.pitchDegrees) < 1 && abs(pr.rollDegrees) < 1 ? .green : .yellow)
                .frame(width: 24, height: 24)
                .offset(x: off.x, y: off.y)
        }
        .onAppear { att.start() }
        .onDisappear { att.stop() }
    }
}

struct WatchSettingsView: View {
    @AppStorage("use24Hour") private var use24Hour = false
    @AppStorage("crashReportingOptIn") private var crashOptIn = false
    @AppStorage("analyticsOptIn") private var analyticsOptIn = false
    var body: some View {
        Form {
            Toggle("24-hour", isOn: $use24Hour)
            Toggle("Crash reports", isOn: $crashOptIn)
            Toggle("Analytics", isOn: $analyticsOptIn)
        }
    }
}
