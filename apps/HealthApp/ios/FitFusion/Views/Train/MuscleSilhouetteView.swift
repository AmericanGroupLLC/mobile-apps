import SwiftUI
import FitFusionCore

/// Stylised anatomy silhouette with tappable muscle regions. Toggles between
/// a Front and Back view and reports the selected `MuscleGroup` to the
/// parent. Built entirely with SwiftUI shapes \u{2014} no image assets shipped.
struct MuscleSilhouetteView: View {
    @Binding var view: BodyView
    @Binding var selected: MuscleGroup?

    var body: some View {
        VStack(spacing: 8) {
            Picker("View", selection: $view) {
                ForEach(BodyView.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ZStack {
                silhouette
                regions
            }
            .frame(maxWidth: 260, maxHeight: 380)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))

            if let m = selected {
                Text("Selected: \(m.label)")
                    .font(.caption.bold())
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.indigo.opacity(0.15), in: Capsule())
            } else {
                Text("Tap a muscle group")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var silhouette: some View {
        // Stylised body silhouette built from rounded shapes.
        ZStack {
            // Head
            Circle().fill(Color.gray.opacity(0.18))
                .frame(width: 56, height: 56)
                .offset(y: -150)
            // Torso
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.18))
                .frame(width: 130, height: 150)
                .offset(y: -25)
            // Arms (left + right)
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 28, height: 130)
                    .offset(x: side * 80, y: -25)
            }
            // Legs (left + right)
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 38, height: 150)
                    .offset(x: side * 22, y: 100)
            }
        }
    }

    private var regions: some View {
        ZStack {
            ForEach(visibleRegions) { region in
                muscleRegion(region)
            }
        }
    }

    @ViewBuilder
    private func muscleRegion(_ region: MuscleRegion) -> some View {
        let isSelected = selected == region.muscle
        RoundedRectangle(cornerRadius: region.cornerRadius)
            .fill(isSelected
                  ? region.muscle.color.opacity(0.85)
                  : region.muscle.color.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: region.cornerRadius)
                    .stroke(.white.opacity(0.8), lineWidth: isSelected ? 2 : 0)
            )
            .frame(width: region.size.width, height: region.size.height)
            .offset(x: region.offset.x, y: region.offset.y)
            .onTapGesture { selected = region.muscle }
    }

    private var visibleRegions: [MuscleRegion] {
        view == .front ? Self.frontRegions : Self.backRegions
    }

    // MARK: - Region layout

    private struct MuscleRegion: Identifiable {
        let muscle: MuscleGroup
        let size: CGSize
        let offset: CGPoint
        let cornerRadius: CGFloat
        var id: String { muscle.rawValue }
    }

    private static let frontRegions: [MuscleRegion] = [
        .init(muscle: .shoulders, size: .init(width: 110, height: 26),
              offset: .init(x: 0, y: -88), cornerRadius: 12),
        .init(muscle: .chest,     size: .init(width: 110, height: 50),
              offset: .init(x: 0, y: -56), cornerRadius: 14),
        .init(muscle: .biceps,    size: .init(width: 24, height: 56),
              offset: .init(x: -80, y: -50), cornerRadius: 10),
        .init(muscle: .biceps,    size: .init(width: 24, height: 56),
              offset: .init(x: 80, y: -50), cornerRadius: 10),
        .init(muscle: .core,      size: .init(width: 70, height: 80),
              offset: .init(x: 0, y: 12), cornerRadius: 12),
        .init(muscle: .obliques,  size: .init(width: 16, height: 60),
              offset: .init(x: -50, y: 14), cornerRadius: 8),
        .init(muscle: .obliques,  size: .init(width: 16, height: 60),
              offset: .init(x: 50, y: 14), cornerRadius: 8),
        .init(muscle: .forearms,  size: .init(width: 24, height: 50),
              offset: .init(x: -80, y: 18), cornerRadius: 8),
        .init(muscle: .forearms,  size: .init(width: 24, height: 50),
              offset: .init(x: 80, y: 18), cornerRadius: 8),
        .init(muscle: .quads,     size: .init(width: 34, height: 100),
              offset: .init(x: -22, y: 90), cornerRadius: 12),
        .init(muscle: .quads,     size: .init(width: 34, height: 100),
              offset: .init(x: 22, y: 90), cornerRadius: 12),
        .init(muscle: .calves,    size: .init(width: 28, height: 50),
              offset: .init(x: -22, y: 165), cornerRadius: 10),
        .init(muscle: .calves,    size: .init(width: 28, height: 50),
              offset: .init(x: 22, y: 165), cornerRadius: 10),
    ]

    private static let backRegions: [MuscleRegion] = [
        .init(muscle: .traps,     size: .init(width: 70, height: 28),
              offset: .init(x: 0, y: -100), cornerRadius: 12),
        .init(muscle: .back,      size: .init(width: 110, height: 40),
              offset: .init(x: 0, y: -64), cornerRadius: 12),
        .init(muscle: .lats,      size: .init(width: 50, height: 80),
              offset: .init(x: -32, y: -10), cornerRadius: 16),
        .init(muscle: .lats,      size: .init(width: 50, height: 80),
              offset: .init(x: 32, y: -10), cornerRadius: 16),
        .init(muscle: .triceps,   size: .init(width: 24, height: 56),
              offset: .init(x: -80, y: -50), cornerRadius: 10),
        .init(muscle: .triceps,   size: .init(width: 24, height: 56),
              offset: .init(x: 80, y: -50), cornerRadius: 10),
        .init(muscle: .lowerBack, size: .init(width: 80, height: 30),
              offset: .init(x: 0, y: 30), cornerRadius: 10),
        .init(muscle: .glutes,    size: .init(width: 90, height: 50),
              offset: .init(x: 0, y: 70), cornerRadius: 14),
        .init(muscle: .hamstrings, size: .init(width: 34, height: 80),
              offset: .init(x: -22, y: 130), cornerRadius: 12),
        .init(muscle: .hamstrings, size: .init(width: 34, height: 80),
              offset: .init(x: 22, y: 130), cornerRadius: 12),
        .init(muscle: .calves,    size: .init(width: 28, height: 50),
              offset: .init(x: -22, y: 195), cornerRadius: 10),
        .init(muscle: .calves,    size: .init(width: 28, height: 50),
              offset: .init(x: 22, y: 195), cornerRadius: 10),
    ]
}

extension MuscleGroup {
    /// Color used both on the silhouette and as the swatch in lists.
    var color: Color {
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
