import SwiftUI
import FitFusionCore

/// Watch-friendly anatomy entry. Three tappable region tiles (Upper / Core /
/// Lower) plus a name-search escape hatch. Each tile drills into
/// `MusclesByRegionView` \u{2192} `MuscleExercisesView` \u{2192} `WatchExerciseDetailView`
/// \u{2192} `QuickExerciseLogView`.
///
/// The full silhouette UX from iPhone isn't tappable on a 41 mm screen, so we
/// trade pixels for tap-target size on the wrist.
struct AnatomyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Anatomy")
                        .font(.headline).foregroundStyle(.white)

                    NavigationLink {
                        MusclesByRegionView(region: .upper)
                    } label: {
                        regionTile(title: "Upper Body",
                                   subtitle: "Chest \u{00b7} Back \u{00b7} Arms \u{00b7} Shoulders",
                                   icon: "figure.arms.open",
                                   colors: [.red, .pink])
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        MusclesByRegionView(region: .core)
                    } label: {
                        regionTile(title: "Core",
                                   subtitle: "Abs \u{00b7} Obliques \u{00b7} Lower back",
                                   icon: "figure.core.training",
                                   colors: [.teal, .cyan])
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        MusclesByRegionView(region: .lower)
                    } label: {
                        regionTile(title: "Lower Body",
                                   subtitle: "Quads \u{00b7} Hamstrings \u{00b7} Glutes \u{00b7} Calves",
                                   icon: "figure.run",
                                   colors: [.green, .indigo])
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AllExercisesListView()
                    } label: {
                        regionTile(title: "Browse all",
                                   subtitle: "Search the full library",
                                   icon: "books.vertical.fill",
                                   colors: [.indigo, .purple])
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            }
            .containerBackground(.red.gradient, for: .navigation)
        }
    }

    private func regionTile(title: String, subtitle: String,
                            icon: String, colors: [Color]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.18), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.bold)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 9)).foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2).foregroundStyle(.white.opacity(0.85))
        }
        .padding(8)
        .background(LinearGradient(colors: colors,
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Three-way grouping of `MuscleGroup` for the watch's tiny screen.
enum WatchBodyRegion: String, CaseIterable, Identifiable {
    case upper, core, lower

    var id: String { rawValue }
    var title: String {
        switch self {
        case .upper: return "Upper Body"
        case .core:  return "Core"
        case .lower: return "Lower Body"
        }
    }
    var muscles: [MuscleGroup] {
        switch self {
        case .upper: return [.chest, .back, .lats, .traps, .shoulders, .biceps, .triceps, .forearms]
        case .core:  return [.core, .obliques, .lowerBack]
        case .lower: return [.glutes, .quads, .hamstrings, .calves, .adductors, .abductors]
        }
    }
}
