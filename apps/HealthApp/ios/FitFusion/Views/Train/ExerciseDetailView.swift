import SwiftUI
import FitFusionCore
import AVKit

/// Detail page for a single exercise. Shows instructions, form tips, muscle
/// chips, equipment, and an embedded form video when `videoURL` is set.
/// "Log a set" button opens the workout logger.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @State private var showLogger = false
    @State private var personalRecord: Double?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                muscleChipsRow

                if let pr = personalRecord, pr > 0 {
                    HStack {
                        Label("PR: \(format(pr)) kg", systemImage: "trophy.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.yellow)
                        Spacer()
                    }
                    .padding(12)
                    .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

                videoOrPlaceholder

                section(title: "Instructions") {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)")
                                .font(.caption.bold())
                                .frame(width: 22, height: 22)
                                .background(.indigo, in: Circle())
                                .foregroundStyle(.white)
                            Text(step).font(.subheadline)
                            Spacer()
                        }
                    }
                }

                if !exercise.formTips.isEmpty {
                    section(title: "Form tips") {
                        ForEach(exercise.formTips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text(tip).font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                }

                if !exercise.isStretch {
                    Button { showLogger = true } label: {
                        Label("Log a Set", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(colors: [.orange, .pink],
                                                       startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogger) {
            WorkoutLoggerView(exercise: exercise)
        }
        .task {
            personalRecord = CloudStore.shared.personalRecord(for: exercise.id)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: heroColors,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            HStack(spacing: 12) {
                Image(systemName: exercise.equipment.systemImage)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.equipment.label.uppercased())
                        .font(.caption2).bold()
                        .foregroundStyle(.white.opacity(0.85))
                    Text(exercise.name).font(.title2.bold()).foregroundStyle(.white)
                    Text(exercise.difficulty.label.capitalized).font(.caption).foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding()
        }
    }

    private var heroColors: [Color] {
        let primary = exercise.primaryMuscles.first?.color ?? .orange
        return [primary, primary.opacity(0.6), .purple]
    }

    private var muscleChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(exercise.primaryMuscles) { m in
                    chip(text: m.label, color: m.color, prominent: true)
                }
                ForEach(exercise.secondaryMuscles) { m in
                    chip(text: m.label, color: m.color, prominent: false)
                }
            }
        }
    }

    private func chip(text: String, color: Color, prominent: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(color.opacity(prominent ? 0.7 : 0.25),
                        in: Capsule())
            .foregroundStyle(prominent ? .white : .primary)
    }

    @ViewBuilder
    private var videoOrPlaceholder: some View {
        if let url = exercise.videoURL {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: heroColors,
                                         startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.2))
                    .frame(height: 180)
                VStack(spacing: 6) {
                    Image(systemName: exercise.equipment.systemImage)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(exercise.primaryMuscles.first?.color ?? .secondary)
                    Text("Form video coming soon")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
