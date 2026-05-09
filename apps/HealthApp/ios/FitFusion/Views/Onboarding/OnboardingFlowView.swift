import SwiftUI
import FitFusionCore

/// Multi-page first-launch onboarding. Welcome \u{2192} Profile setup \u{2192} Goal \u{2192} Done.
/// Persists `didOnboard` in UserDefaults so this view only shows once.
struct OnboardingFlowView: View {
    @AppStorage(AuthStore.didOnboardKey) private var didOnboard: Bool = false
    @State private var page = 0

    @State private var name = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sex: ProfileSex = .female
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 65
    @State private var unitsImperial = false
    @State private var goal: HealthGoal = .maintain

    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange.opacity(0.18),
                                    .pink.opacity(0.16),
                                    .indigo.opacity(0.18)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            TabView(selection: $page) {
                welcome.tag(0)
                profileSetup.tag(1)
                goalSetup.tag(2)
                done.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Pages

    private var welcome: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(LinearGradient(colors: [.orange, .pink, .purple],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                Image(systemName: "heart.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Welcome to MyHealth").font(.largeTitle).bold()
            Text("Your personal fitness OS \u{2014} fitness, food, sleep, mood, vitals, and biological age. All on your device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            primaryButton(title: "Get started") { withAnimation { page = 1 } }
        }
        .padding()
    }

    private var profileSetup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Tell us about you").font(.title2).bold()
                Text("This personalises readiness, calories, and biological age. Stays on this device.")
                    .font(.footnote).foregroundStyle(.secondary)

                groupedField("Name") {
                    TextField("Your name", text: $name).textContentType(.name)
                }

                groupedField("Date of birth") {
                    DatePicker("DOB", selection: $birthDate, displayedComponents: .date)
                        .labelsHidden()
                }

                groupedField("Sex (for HealthKit)") {
                    Picker("", selection: $sex) {
                        ForEach(ProfileSex.allCases) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)
                }

                Toggle("Use imperial units (ft/lb)", isOn: $unitsImperial)
                    .padding(.vertical, 4)

                groupedField(unitsImperial ? "Height (cm-equivalent)" : "Height (cm)") {
                    Stepper(value: $heightCm, in: 120...220, step: 1) {
                        Text("\(Int(heightCm)) cm")
                    }
                }
                groupedField(unitsImperial ? "Weight (kg-equivalent)" : "Weight (kg)") {
                    Stepper(value: $weightKg, in: 30...200, step: 0.5) {
                        Text(String(format: "%.1f kg", weightKg))
                    }
                }

                primaryButton(title: "Continue") { withAnimation { page = 2 } }
                    .disabled(name.isEmpty)
                    .padding(.top, 12)
            }
            .padding()
        }
    }

    private var goalSetup: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("What's your goal?").font(.title2).bold().padding(.horizontal)
            VStack(spacing: 8) {
                ForEach(HealthGoal.allCases) { g in
                    Button {
                        goal = g
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: g.icon)
                                .font(.title3.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(.indigo.opacity(0.18), in: Circle())
                                .foregroundStyle(.indigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.label).font(.headline)
                                Text(g.subtitle).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if goal == g {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.indigo)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            Spacer()
            primaryButton(title: "Almost done") { withAnimation { page = 3 } }
                .padding(.horizontal)
        }
    }

    private var done: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.green, .indigo],
                                                startPoint: .top, endPoint: .bottom))
            Text("You're all set, \(name).").font(.title2).bold()
            Text("Open Vitals to scan your data. Add a medicine reminder. Log a meal. Everything stays private on this device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            primaryButton(title: "Enter MyHealth") {
                CloudStore.shared.saveProfile(
                    name: name,
                    birthDateISO: ISO8601DateFormatter().string(from: birthDate),
                    sex: sex.rawValue,
                    heightCm: heightCm,
                    weightKg: weightKg,
                    goal: goal.rawValue,
                    unitsImperial: unitsImperial
                )
                didOnboard = true
            }
        }
        .padding()
    }

    // MARK: - Helpers

    @ViewBuilder
    private func groupedField<Content: View>(_ label: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            content()
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).bold()
                .frame(maxWidth: .infinity).padding()
                .background(LinearGradient(colors: [.orange, .pink],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Onboarding domain enums

enum ProfileSex: String, CaseIterable, Identifiable {
    case female, male, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum HealthGoal: String, CaseIterable, Identifiable {
    case lose = "lose_weight"
    case maintain = "maintain"
    case gain = "build_muscle"
    case endurance = "endurance"
    case general = "general_wellness"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .lose: return "Lose weight"
        case .maintain: return "Maintain"
        case .gain: return "Build muscle"
        case .endurance: return "Improve endurance"
        case .general: return "General wellness"
        }
    }
    var subtitle: String {
        switch self {
        case .lose: return "Calorie deficit + steady cardio"
        case .maintain: return "Stay where you are, feel great"
        case .gain: return "Progressive overload + protein"
        case .endurance: return "Aerobic base + tempo work"
        case .general: return "Move daily, sleep well, eat well"
        }
    }
    var icon: String {
        switch self {
        case .lose: return "figure.walk.motion"
        case .maintain: return "scalemass.fill"
        case .gain: return "figure.strengthtraining.traditional"
        case .endurance: return "figure.run"
        case .general: return "leaf.fill"
        }
    }
}
