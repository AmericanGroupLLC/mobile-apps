import SwiftUI
import FitFusionCore

/// Workout tab home. Consolidates entry points to the existing
/// RunTrackerView, WorkoutLoggerView, and SleepRecoveryView surfaces, plus
/// the new RPE rating sheet (the one new "real" workout-tab feature in
/// week 1). Other workout-tab destinations (Wellness insights, Community
/// hub, Challenge detail) ship as ComingSoon stubs.
struct WorkoutHomeView: View {
    @State private var showRPE = false
    @State private var showHeaderProfile = false
    @State private var showHeaderBell = false

    private let tint = CarePlusPalette.workoutPink

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppHeader(tab: .workout,
                          onProfile: { showHeaderProfile = true },
                          onBell: { showHeaderBell = true })

                ScrollView {
                    VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {

                        // ─── Activity rings header ─────────────────────
                        VStack(spacing: 8) {
                            ActivityRingsView(move: 0.72, exercise: 0.45, stand: 0.85)
                            HStack(spacing: 24) {
                                statColumn("Move", "420")
                                statColumn("Exercise", "28")
                                statColumn("Stand", "9/12")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        wellnessInsight
                        Button {
                            showRPE = true
                        } label: {
                            HStack(spacing: CarePlusSpacing.md) {
                                Image(systemName: "gauge.with.dots.needle.67percent")
                                    .font(.title2.weight(.semibold))
                                    .frame(width: 40, height: 40)
                                    .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rate that workout (RPE)").font(.headline)
                                    Text("How hard did it feel? 1–10 scale.")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(CarePlusSpacing.md)
                            .background(CarePlusPalette.surfaceElevated,
                                        in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
                        }.buttonStyle(.plain)

                        sectionHeader("Cardio")
                        NavigationLink {
                            RunTrackerView()
                        } label: {
                            tile(symbol: "figure.run", title: "Run / walk tracker",
                                 subtitle: "GPS pace + map.")
                        }.buttonStyle(.plain)

                        sectionHeader("Strength")
                        NavigationLink {
                            WorkoutLoggerView()
                        } label: {
                            tile(symbol: "figure.strengthtraining.traditional",
                                 title: "Workout logger",
                                 subtitle: "Sets, reps, perceived load.")
                        }.buttonStyle(.plain)

                        sectionHeader("Recovery")
                        NavigationLink {
                            SleepRecoveryView()
                        } label: {
                            tile(symbol: "moon.stars.fill",
                                 title: "Sleep & HRV",
                                 subtitle: "Stages, recovery score, mood.")
                        }.buttonStyle(.plain)

                        sectionHeader("Coming soon")
                        NavigationLink {
                            ComingSoon(title: "Wellness insights",
                                       symbol: "chart.line.uptrend.xyaxis",
                                       tint: tint, etaWeek: 5)
                        } label: {
                            tile(symbol: "chart.line.uptrend.xyaxis",
                                 title: "Wellness insights",
                                 subtitle: "Weekly summary across cardio, strength, sleep.")
                        }.buttonStyle(.plain)
                        NavigationLink {
                            ComingSoon(title: "Community hub", symbol: "person.3.fill",
                                       tint: tint, etaWeek: 6)
                        } label: {
                            tile(symbol: "person.3.fill", title: "Community hub",
                                 subtitle: "Friends, badges, leaderboards.")
                        }.buttonStyle(.plain)
                        NavigationLink {
                            ComingSoon(title: "Challenge detail", symbol: "flag.checkered.2.crossed",
                                       tint: tint, etaWeek: 6)
                        } label: {
                            tile(symbol: "flag.checkered.2.crossed",
                                 title: "Challenges", subtitle: "Join a challenge or start your own.")
                        }.buttonStyle(.plain)
                    }
                    .padding(CarePlusSpacing.lg)
                }
            }
            .background(CarePlusPalette.surface.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showRPE) { RPERatingSheet() }
            .sheet(isPresented: $showHeaderProfile) {
                NavigationStack { ProfileScreen() }
            }
            .sheet(isPresented: $showHeaderBell) {
                NewsDrawerSheet().presentationDetents([.medium, .large])
            }
        }
        .tint(tint)
    }

    private var wellnessInsight: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles").foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Wellness insight").font(.caption.weight(.semibold)).foregroundStyle(tint)
                Text("RHR lowest on 8k step days.").font(.subheadline)
            }
            Spacer()
        }
        .padding(CarePlusSpacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private func statColumn(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }

    private func sectionHeader(_ s: String) -> some View {
        Text(s).font(CarePlusType.titleSM)
            .padding(.top, CarePlusSpacing.sm)
    }

    private func tile(symbol: String, title: String, subtitle: String) -> some View {
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
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }
}
