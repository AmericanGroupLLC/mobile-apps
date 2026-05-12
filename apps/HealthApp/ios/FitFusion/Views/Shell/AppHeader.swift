import SwiftUI
import FitFusionCore

/// Global app header used across all four primary tabs. Avatar on the left
/// opens Profile; bell on the right opens the News drawer (3 inner tabs:
/// Urgent / For You / Wellness). Tab title in the center.
public struct AppHeader: View {
    let tab: CarePlusTab
    let onProfile: () -> Void
    let onBell: () -> Void

    public init(tab: CarePlusTab,
                onProfile: @escaping () -> Void,
                onBell: @escaping () -> Void) {
        self.tab = tab
        self.onProfile = onProfile
        self.onBell = onBell
    }

    public var body: some View {
        HStack(spacing: CarePlusSpacing.md) {
            Button(action: onProfile) {
                ZStack {
                    Circle().fill(tab.accent.opacity(0.18))
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(tab.accent)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 0) {
                Text(tab.label).font(CarePlusType.titleSM)
                Text("Care+").font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onBell) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(.regularMaterial, in: Circle())
                    Circle()
                        .fill(CarePlusPalette.danger)
                        .frame(width: 8, height: 8)
                        .offset(x: -4, y: 4)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CarePlusSpacing.lg)
        .padding(.vertical, CarePlusSpacing.sm)
        .background(.thinMaterial)
    }
}
