import SwiftUI
import FitFusionCore

/// Watch-only color swatches per `MuscleGroup`. Mirrors the iOS color choices
/// in `MuscleSilhouetteView.swift` so a chest = red, lats = indigo, etc., are
/// consistent across platforms.
extension MuscleGroup {
    var watchColor: Color {
        switch self {
        case .chest:      return .red
        case .back:       return .purple
        case .lats:       return .indigo
        case .traps:      return .blue
        case .shoulders:  return .orange
        case .biceps:     return .pink
        case .triceps:    return .mint
        case .forearms:   return .yellow
        case .core:       return .teal
        case .obliques:   return .cyan
        case .lowerBack:  return .brown
        case .glutes:     return .pink
        case .quads:      return .green
        case .hamstrings: return .red
        case .calves:     return .indigo
        case .adductors:  return .purple
        case .abductors:  return .blue
        }
    }
}

/// List of muscles for a given watch region. Tap one \u{2192} `MuscleExercisesView`.
struct MusclesByRegionView: View {
    let region: WatchBodyRegion

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(region.muscles) { muscle in
                    NavigationLink {
                        MuscleExercisesView(muscle: muscle)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(muscle.watchColor)
                                .frame(width: 14, height: 14)
                            Text(muscle.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(ExerciseLibrary.filter(muscle: muscle).count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.85))
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(.white.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .navigationTitle(region.title)
        .containerBackground(LinearGradient(colors: [.red, .purple],
                                            startPoint: .topLeading, endPoint: .bottomTrailing),
                             for: .navigation)
    }
}
