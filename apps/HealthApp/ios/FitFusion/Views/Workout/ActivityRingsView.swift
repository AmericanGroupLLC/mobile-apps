import SwiftUI
import FitFusionCore

/// Apple-style activity rings (Move / Exercise / Stand). Pure SwiftUI
/// Canvas — no UIKit. Designed to read from `HKActivitySummary` once
/// HealthKit is wired in week 2; today the values are placeholders.
public struct ActivityRingsView: View {
    public let move: Double         // 0...1 progress (kcal)
    public let exercise: Double     // 0...1 progress (min)
    public let stand: Double        // 0...1 progress (hours)

    /// Diameter of the outer ring. Inner rings are stepped down by
    /// `ringStep` per layer.
    public var diameter: CGFloat = 180
    public var lineWidth: CGFloat = 14
    public var ringStep: CGFloat = 22

    public init(move: Double, exercise: Double, stand: Double,
                diameter: CGFloat = 180, lineWidth: CGFloat = 14,
                ringStep: CGFloat = 22) {
        self.move = move
        self.exercise = exercise
        self.stand = stand
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.ringStep = ringStep
    }

    public var body: some View {
        ZStack {
            ring(progress: move,
                 outer: CarePlusPalette.workoutPink,
                 size: diameter)
            ring(progress: exercise,
                 outer: CarePlusPalette.trainGreen,
                 size: diameter - ringStep * 2)
            ring(progress: stand,
                 outer: CarePlusPalette.careBlue,
                 size: diameter - ringStep * 4)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity rings")
        .accessibilityValue(
            "Move \(Int(move*100))%, Exercise \(Int(exercise*100))%, Stand \(Int(stand*100))%"
        )
    }

    private func ring(progress: Double, outer: Color, size: CGFloat) -> some View {
        let p = max(0, min(1, progress))
        return ZStack {
            Circle().stroke(outer.opacity(0.18),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(p))
                .stroke(outer,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: p)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ActivityRingsView(move: 0.72, exercise: 0.45, stand: 0.85)
        .padding()
}
