import SwiftUI

struct TimerView: View {
    @State private var remaining: Int = 60
    @State private var total: Int = 60
    @State private var running = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            Text(format(remaining))
                .font(.system(size: 28, weight: .thin, design: .monospaced))
            HStack {
                Button("-") { if !running { total = max(5, total - 5); remaining = total } }
                Button(running ? "Pause" : "Start") {
                    if !running && remaining == 0 { remaining = total }
                    running.toggle()
                }
                .tint(running ? .orange : .green)
                Button("+") { if !running { total += 5; remaining = total } }
            }
            .buttonStyle(.bordered)
        }
        .onReceive(timer) { _ in
            guard running, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 { running = false }
        }
    }

    private func format(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
