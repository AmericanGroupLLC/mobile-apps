import SwiftUI
import PocketCore

struct CompassView: View {
    @StateObject private var heading = HeadingService()
    @AppStorage("useTrueHeading") private var useTrueHeading = true

    private var displayDeg: Double {
        useTrueHeading ? heading.trueHeading : heading.magneticHeading
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(HeadingMath.cardinalLabel(forDegrees: displayDeg))
                .font(.system(size: 56, weight: .bold))
            ZStack {
                Circle().stroke(.secondary, lineWidth: 1).frame(width: 280, height: 280)
                ForEach(0..<8) { i in
                    let labels = ["N","NE","E","SE","S","SW","W","NW"]
                    Text(labels[i])
                        .font(.caption.weight(.bold))
                        .offset(y: -130)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                Image(systemName: "location.north.fill")
                    .font(.system(size: 60)).foregroundColor(.red)
                    .rotationEffect(.degrees(-displayDeg))
                    .animation(.easeInOut(duration: 0.2), value: displayDeg)
            }
            Text(String(format: "%.0f°", displayDeg)).font(.title3.monospacedDigit())
            if let loc = heading.location {
                Text(String(format: "%.4f, %.4f", loc.latitude, loc.longitude))
                    .font(.callout.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            Toggle("True (vs magnetic)", isOn: $useTrueHeading).padding(.horizontal)
        }
        .navigationTitle("Compass")
        .onAppear { heading.start() }
        .onDisappear { heading.stop() }
    }
}
