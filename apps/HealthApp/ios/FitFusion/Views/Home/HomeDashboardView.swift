import SwiftUI
import FitFusionCore

struct HomeDashboardView: View {
    @EnvironmentObject var auth: AuthStore
    @EnvironmentObject var hk: iOSHealthKitManager
    @EnvironmentObject var bridge: WatchBridge
    @EnvironmentObject var mirror: WorkoutMirrorReceiver
    @EnvironmentObject var vitals: VitalsService

    @State private var readiness: ReadinessResponse?
    @State private var todayMeals: MealListResponse?
    @State private var loading = false
    @State private var error: String?
    @State private var suggestion: AdaptivePlanner.Suggestion?
    @State private var showStateOfMind = false
    @State private var showMirrored = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greeting
                    readinessCard
                    suggestedWorkoutCard
                    vitalsCard
                    stateOfMindCard
                    todayRingsRow
                    quickActions
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: { Image(systemName: "arrow.clockwise") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) { auth.logout() } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .task { await refresh() }
            .refreshable { await refresh() }
            .sheet(isPresented: $showStateOfMind) {
                StateOfMindLogger()
                    .environmentObject(hk)
                    .environmentObject(CloudStore.shared)
            }
            .onChange(of: mirror.isActive) { _, isActive in
                showMirrored = isActive
            }
            .sheet(isPresented: $showMirrored) {
                MirroredWorkoutView(receiver: mirror)
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello,").font(.subheadline).foregroundStyle(.secondary)
            Text(auth.user?.name ?? "Athlete")
                .font(.largeTitle).fontWeight(.bold)
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Readiness")
                    .font(.headline)
                Spacer()
                if let r = readiness {
                    Text("\(r.score)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(readinessColor(r.score))
                }
            }
            if let r = readiness {
                ProgressView(value: Double(r.score), total: 100)
                    .tint(readinessColor(r.score))
                Text(r.suggestion)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    statTile(title: "HRV", value: r.hrv_avg.map { String(format: "%.0f ms", $0) } ?? "—")
                    statTile(title: "Sleep", value: r.sleep_hrs.map { String(format: "%.1f h", $0) } ?? "—")
                    statTile(title: "Workout", value: r.workout_minutes.map { "\(Int($0)) min" } ?? "—")
                }
            } else if loading {
                ProgressView()
            } else if let e = error {
                Text(e).font(.caption).foregroundStyle(.red)
            } else {
                Text("Pull to refresh").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(LinearGradient(colors: [.orange.opacity(0.18), .pink.opacity(0.12), .purple.opacity(0.12)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var suggestedWorkoutCard: some View {
        if let s = suggestion {
            NavigationLink {
                WorkoutDetailView(template: s.template)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.bold))
                        .padding(12)
                        .background(.indigo.opacity(0.2), in: Circle())
                        .foregroundStyle(.indigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Suggested Workout").font(.caption).bold()
                            .foregroundStyle(.secondary)
                        Text(s.template.name).font(.headline)
                        Text(s.rationale).font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text("Confidence: \(Int(s.confidence * 100))%")
                            .font(.caption2).foregroundStyle(.indigo)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
    }

    private var vitalsCard: some View {
        NavigationLink {
            VitalsView()
                .environmentObject(vitals)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.title2.weight(.bold))
                    .padding(12)
                    .background(.red.opacity(0.18), in: Circle())
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vitals & Biological Age").font(.headline)
                    Text("HR \u{00b7} HRV \u{00b7} SpO\u{2082} \u{00b7} BP \u{00b7} VO\u{2082}Max \u{00b7} sleep \u{00b7} body comp")
                        .font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(LinearGradient(colors: [.red.opacity(0.12), .orange.opacity(0.10)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var stateOfMindCard: some View {
        Button { showStateOfMind = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.title2.weight(.bold))
                    .padding(12)
                    .background(.pink.opacity(0.2), in: Circle())
                    .foregroundStyle(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("How are you?").font(.headline)
                    Text("Capture a quick state-of-mind entry")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var todayRingsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.headline)
            HStack(spacing: 12) {
                ringTile(title: "Calories",
                         value: todayMeals.map { Int($0.totals.kcal) } ?? 0,
                         unit: "kcal", color: .orange)
                ringTile(title: "Protein",
                         value: todayMeals.map { Int($0.totals.protein_g) } ?? 0,
                         unit: "g", color: .pink)
                ringTile(title: "Steps",
                         value: hk.todaySteps,
                         unit: "", color: .green)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick start")
                .font(.headline)
            HStack(spacing: 12) {
                NavigationLink {
                    TrainView()
                } label: {
                    quickTile(icon: "figure.strengthtraining.traditional", title: "Workout", color: .blue)
                }
                NavigationLink {
                    RunTrackerView()
                } label: {
                    quickTile(icon: "figure.run", title: "Run", color: .green)
                }
                NavigationLink {
                    NutritionView()
                } label: {
                    quickTile(icon: "fork.knife", title: "Meal", color: .orange)
                }
            }
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).bold()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func ringTile(title: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)\(unit.isEmpty ? "" : " \(unit)")")
                .font(.title3).bold()
                .foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func quickTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func readinessColor(_ score: Int) -> Color {
        switch score {
        case ..<40: return .red
        case ..<70: return .yellow
        default:    return .green
        }
    }

    private func refresh() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            async let r = APIClient.shared.readiness()
            async let m = APIClient.shared.todayMeals()
            let (rResp, mResp) = try await (r, m)
            readiness = rResp
            todayMeals = mResp
            await hk.refreshTodaySteps()

            // Adaptive planner suggestion (on-device).
            let inputs = AdaptivePlanner.Inputs(
                readiness: rResp.score,
                recentHRV: rResp.hrv_avg,
                lastSleepHrs: rResp.sleep_hrs,
                weeklyMinutes: rResp.workout_minutes,
                perceivedExertion: nil
            )
            suggestion = AdaptivePlanner.shared.nextWorkout(for: inputs)

            // Push readiness to the Watch via WCSession
            bridge.push(readinessScore: rResp.score, readinessSuggestion: rResp.suggestion)
            // Persist for App Group → complication / iOS widgets
            UserDefaults(suiteName: "group.com.fitfusion")?
                .set(rResp.score, forKey: "readinessScore")
            UserDefaults(suiteName: "group.com.fitfusion")?
                .set(rResp.suggestion, forKey: "readinessSuggestion")
            // Today's macros for Macro Rings widget
            let totals = mResp.totals
            UserDefaults(suiteName: "group.com.fitfusion")?
                .set(totals.kcal, forKey: "todayKcal")
            UserDefaults(suiteName: "group.com.fitfusion")?
                .set(totals.protein_g, forKey: "todayProtein")
            UserDefaults(suiteName: "group.com.fitfusion")?
                .set(totals.carbs_g, forKey: "todayCarbs")
            UserDefaults(suiteName: "group.com.fitfusion")?
                .set(totals.fat_g, forKey: "todayFat")
        } catch let e as APIError {
            error = e.error
        } catch {
            self.error = error.localizedDescription
        }
    }
}
