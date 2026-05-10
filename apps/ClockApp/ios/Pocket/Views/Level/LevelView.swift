import SwiftUI
import PocketCore

struct LevelView: View {
    @StateObject private var attitude = AttitudeService()

    var body: some View {
        VStack(spacing: 24) {
            let pr = attitude.pitchRoll
            let isFlat = LevelMath.isFlat(pitch: pr.pitchDegrees, roll: pr.rollDegrees)

            if isFlat {
                bullseye(pr: pr)
            } else {
                tilted(pr: pr)
            }
            Text(String(format: "Pitch %.1f° · Roll %.1f°", pr.pitchDegrees, pr.rollDegrees))
                .font(.callout.monospacedDigit())
                .foregroundColor(.secondary)
        }
        .navigationTitle("Level")
        .onAppear { attitude.start() }
        .onDisappear { attitude.stop() }
    }

    private func bullseye(pr: PitchRoll) -> some View {
        ZStack {
            Circle().stroke(.secondary, lineWidth: 1).frame(width: 280, height: 280)
            Circle().stroke(.tertiary, lineWidth: 1).frame(width: 140, height: 140)
            let off = LevelMath.bubbleOffset(forPitch: pr.pitchDegrees, roll: pr.rollDegrees, radius: 140)
            Circle()
                .fill(abs(pr.pitchDegrees) < 1 && abs(pr.rollDegrees) < 1 ? .green : .yellow)
                .frame(width: 36, height: 36)
                .offset(x: off.x, y: off.y)
                .animation(.easeInOut(duration: 0.1), value: pr)
        }
    }

    private func tilted(pr: PitchRoll) -> some View {
        VStack(spacing: 12) {
            Text(String(format: "%.1f°", abs(pr.rollDegrees))).font(.system(size: 60, weight: .light))
            ZStack {
                Capsule().stroke(.secondary, lineWidth: 1).frame(width: 280, height: 60)
                Capsule().fill(.green).frame(width: 60, height: 56).offset(x: max(-110, min(110, CGFloat(pr.rollDegrees) * 3)))
            }
        }
    }
}
