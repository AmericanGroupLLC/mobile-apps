import SwiftUI
import FitFusionCore

/// Placeholder destination for screens that exist in the Care+ spec but
/// aren't yet implemented. Renders a friendly empty state with a "coming
/// soon" badge so navigation works end-to-end and clicking through the
/// 30+ stub destinations never crashes.
public struct ComingSoon: View {
    let title: String
    let symbol: String
    let tint: Color
    let etaWeek: Int?

    public init(title: String, symbol: String = "sparkles",
                tint: Color = .accentColor, etaWeek: Int? = nil) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.etaWeek = etaWeek
    }

    public var body: some View {
        VStack(spacing: CarePlusSpacing.lg) {
            Spacer()
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 110, height: 110)
                Image(systemName: symbol)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(spacing: CarePlusSpacing.xs) {
                Text(title).font(CarePlusType.title)
                Text("Coming soon")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(tint.opacity(0.18), in: Capsule())
                    .foregroundStyle(tint)
            }

            if let week = etaWeek {
                Text("Planned for week \(week) of the Care+ MVP build.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("This screen is part of the Care+ rollout. The plumbing is in place — final UI lands in a future drop.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CarePlusSpacing.xl)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
