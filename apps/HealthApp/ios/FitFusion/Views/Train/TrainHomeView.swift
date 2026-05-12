import SwiftUI
import FitFusionCore

/// Train tab home — adds a "Moderate workout for you" recommendation card
/// above the existing TrainView programs list. Per design-spec guidance,
/// the recommendation is derived from HealthKit-only signals (sleep + HRV
/// + yesterday's training load) — no clinical data.
struct TrainHomeView: View {
    @State private var showHeaderProfile = false
    @State private var showHeaderBell = false

    private let tint = CarePlusPalette.trainGreen

    // Recommendation stub — week-2 wires this to ReadinessEngine.shared.
    private let recommendation = TrainRecommendation(
        intensity: "Moderate",
        title: "35 min recovery flow",
        rationale: "Sleep 6.2h · HRV low",
        tags: ["rate", "run", "care", "diet"]
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppHeader(tab: .train,
                          onProfile: { showHeaderProfile = true },
                          onBell: { showHeaderBell = true })

                ScrollView {
                    VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                        recommendationCard

                        Text("Today's plan").font(CarePlusType.titleSM)
                        planRow(symbol: "figure.cooldown", title: "Warm-up",
                                subtitle: "5 min · 4 moves")
                        planRow(symbol: "dumbbell.fill", title: "Strength block",
                                subtitle: "20 min · 6 moves")
                        planRow(symbol: "wind", title: "Cooldown",
                                subtitle: "10 min · breathwork")

                        // Sedentary alert tile (links to standup timer).
                        NavigationLink {
                            StandupTimerView()
                        } label: {
                            HStack {
                                Image(systemName: "figure.stand").foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sedentary 52 min").font(.headline)
                                    Text("Time to stand up").font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(CarePlusSpacing.md)
                            .background(.orange.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
                        }.buttonStyle(.plain)

                        NavigationLink {
                            TrainView()
                        } label: {
                            HStack {
                                Text("Open program library").font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(CarePlusSpacing.md)
                            .background(CarePlusPalette.surfaceElevated,
                                        in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
                        }.buttonStyle(.plain)
                    }
                    .padding(CarePlusSpacing.lg)
                }
            }
            .background(CarePlusPalette.surface.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showHeaderProfile) { NavigationStack { ProfileScreen() } }
            .sheet(isPresented: $showHeaderBell) {
                NewsDrawerSheet().presentationDetents([.medium, .large])
            }
        }
        .tint(tint)
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(recommendation.intensity) workout for you")
                .font(.subheadline.weight(.semibold)).foregroundStyle(tint)
            Text(recommendation.title).font(CarePlusType.title)
            Text(recommendation.rationale).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(recommendation.tags, id: \.self) { tag in
                    Text(tag).font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.regularMaterial, in: Capsule())
                }
            }
        }
        .padding(CarePlusSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private func planRow(symbol: String, title: String, subtitle: String) -> some View {
        HStack(spacing: CarePlusSpacing.md) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }
}

private struct TrainRecommendation {
    let intensity: String
    let title: String
    let rationale: String
    let tags: [String]
}
