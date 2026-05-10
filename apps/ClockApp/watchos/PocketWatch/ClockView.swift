import SwiftUI

struct ClockView: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(spacing: 6) {
            Text(timeFormatter.string(from: now))
                .font(.system(size: 28, weight: .thin, design: .rounded))
                .monospacedDigit()
            Text(dateFormatter.string(from: now))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onReceive(timer) { now = $0 }
    }
}
