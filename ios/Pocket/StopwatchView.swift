import SwiftUI

struct StopwatchView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var running = false
    @State private var laps: [TimeInterval] = []
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var lastTick = Date()

    var body: some View {
        VStack(spacing: 24) {
            Text(format(elapsed))
                .font(.system(size: 56, weight: .thin, design: .monospaced))
                .padding(.top, 40)

            HStack(spacing: 40) {
                Button(running ? "Lap" : "Reset") {
                    if running { laps.insert(elapsed, at: 0) }
                    else { elapsed = 0; laps.removeAll() }
                }
                .buttonStyle(.bordered)

                Button(running ? "Stop" : "Start") {
                    running.toggle()
                    lastTick = Date()
                }
                .buttonStyle(.borderedProminent)
                .tint(running ? .red : .green)
            }

            List(Array(laps.enumerated()), id: \.offset) { index, lap in
                HStack {
                    Text("Lap \(laps.count - index)")
                    Spacer()
                    Text(format(lap)).monospacedDigit()
                }
            }
        }
        .onReceive(timer) { _ in
            guard running else { return }
            let n = Date()
            elapsed += n.timeIntervalSince(lastTick)
            lastTick = n
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let cs = Int((t - floor(t)) * 100)
        return String(format: "%02d:%02d.%02d", m, s, cs)
    }
}
