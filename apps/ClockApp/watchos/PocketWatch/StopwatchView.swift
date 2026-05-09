import SwiftUI

struct StopwatchView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var running = false
    @State private var lastTick = Date()
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            Text(format(elapsed))
                .font(.system(size: 26, weight: .thin, design: .monospaced))
            HStack {
                Button(running ? "Stop" : "Start") {
                    running.toggle()
                    lastTick = Date()
                }
                .tint(running ? .red : .green)
                Button("Reset") { running = false; elapsed = 0 }
            }
            .buttonStyle(.bordered)
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
