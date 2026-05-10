import SwiftUI

struct TimerView: View {
    @State private var totalSeconds: Int = 60
    @State private var remaining: Int = 60
    @State private var running = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Text(format(remaining))
                .font(.system(size: 72, weight: .thin, design: .monospaced))
                .padding(.top, 40)

            if !running {
                Stepper(value: $totalSeconds, in: 5...3600, step: 5) {
                    Text("Set: \(format(totalSeconds))")
                }
                .padding(.horizontal, 40)
            }

            HStack(spacing: 40) {
                Button("Reset") {
                    running = false
                    remaining = totalSeconds
                }
                .buttonStyle(.bordered)

                Button(running ? "Pause" : "Start") {
                    if !running && remaining == 0 { remaining = totalSeconds }
                    running.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(running ? .orange : .green)
            }
            Spacer()
        }
        .onReceive(timer) { _ in
            guard running, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 { running = false }
        }
        .onChange(of: totalSeconds) { _, new in
            if !running { remaining = new }
        }
    }

    private func format(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
