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
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(timeFormatter.string(from: now))
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .monospacedDigit()
            Text(dateFormatter.string(from: now))
                .font(.title3)
                .foregroundStyle(.secondary)
            AnalogClockView(date: now)
                .frame(width: 220, height: 220)
                .padding(.top, 24)
            Spacer()
        }
        .padding()
        .onReceive(timer) { now = $0 }
    }
}

struct AnalogClockView: View {
    let date: Date

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                Circle().stroke(Color.primary, lineWidth: 2)
                ForEach(0..<12) { i in
                    Rectangle()
                        .frame(width: 2, height: 10)
                        .offset(y: -size / 2 + 8)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                hand(length: size * 0.30, angle: hourAngle, width: 4)
                hand(length: size * 0.42, angle: minuteAngle, width: 3)
                hand(length: size * 0.46, angle: secondAngle, width: 1, color: .red)
                Circle().frame(width: 8, height: 8)
            }
            .position(center)
        }
    }

    private var components: DateComponents {
        Calendar.current.dateComponents([.hour, .minute, .second], from: date)
    }
    private var hourAngle: Angle {
        let h = Double(components.hour ?? 0).truncatingRemainder(dividingBy: 12)
        let m = Double(components.minute ?? 0)
        return .degrees((h + m / 60) * 30)
    }
    private var minuteAngle: Angle {
        .degrees(Double(components.minute ?? 0) * 6)
    }
    private var secondAngle: Angle {
        .degrees(Double(components.second ?? 0) * 6)
    }

    private func hand(length: CGFloat, angle: Angle, width: CGFloat, color: Color = .primary) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(angle)
    }
}

#Preview {
    ClockView()
}
