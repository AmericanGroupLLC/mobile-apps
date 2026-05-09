import SwiftUI
import FitFusionCore

/// Watch detail page \u{2014} tight typography, scrollable instructions + form tips,
/// big "Quick Log" CTA at the bottom (hidden for stretches). Reads the
/// existing PR (heaviest single-rep weight) from CloudKit-synced
/// `ExerciseLogEntity` so the wrist shows the same number the iPhone does.
struct WatchExerciseDetailView: View {
    let exercise: Exercise

    @State private var pr: Double?
    @State private var showLogger = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header

                if let pr, pr > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                        Text("PR \(format(pr)) kg")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.yellow)
                    }
                }

                section(title: "Steps") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\(i + 1).")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text(step)
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                if !exercise.formTips.isEmpty {
                    section(title: "Form tips") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(exercise.formTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.system(size: 9))
                                    Text(tip).font(.caption2).foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }

                if !exercise.isStretch {
                    Button {
                        showLogger = true
                    } label: {
                        Label("Quick Log", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity)
                            .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 4)
                }
            }
            .padding(8)
        }
        .navigationTitle(exercise.name)
        .containerBackground((exercise.primaryMuscles.first?.watchColor ?? .indigo).gradient,
                             for: .navigation)
        .sheet(isPresented: $showLogger) {
            QuickExerciseLogView(exercise: exercise)
        }
        .task {
            pr = CloudStore.shared.personalRecord(for: exercise.id)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.equipment.label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
            HStack {
                ForEach(exercise.primaryMuscles) { m in
                    Text(m.label)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(m.watchColor.opacity(0.6), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.white)
            content()
        }
        .padding(8)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
