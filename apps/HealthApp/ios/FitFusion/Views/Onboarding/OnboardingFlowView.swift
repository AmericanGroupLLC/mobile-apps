import SwiftUI
import FitFusionCore
import HealthKit
import UserNotifications
import CoreLocation

/// Care+ 6-page onboarding flow.
/// Welcome → Login → Birth details → Permissions → Goal → Health issues.
/// Final page sets `didOnboard` and starts the trial timer.
struct OnboardingFlowView: View {
    @AppStorage(AuthStore.didOnboardKey) private var didOnboard: Bool = false
    @AppStorage("careplus.trialStartISO") private var trialStartISO: String = ""
    @State private var page = 0

    // Page-1 (login) — actual auth handled via parent's AuthStore.
    @EnvironmentObject var auth: AuthStore
    @State private var email = ""
    @State private var password = ""

    // Page-2 (birth)
    @State private var name = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var birthTimeApprox = "Morning"
    @State private var birthLocation = ""

    // Page-3 (permissions) state
    @State private var hkGranted = false
    @State private var notifGranted = false
    @State private var locationGranted = false
    @State private var fhirConnected = false

    // Page-4 (goal)
    @State private var goal: HealthGoal = .maintain
    // Page-5 (health issues)
    @StateObject private var hcStore = HealthConditionsStore.shared

    var body: some View {
        ZStack {
            LinearGradient(colors: [CarePlusPalette.careBlue.opacity(0.18),
                                    CarePlusPalette.dietCoral.opacity(0.16),
                                    CarePlusPalette.workoutPink.opacity(0.18)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            TabView(selection: $page) {
                welcome.tag(0)
                loginOrGuest.tag(1)
                birthDetails.tag(2)
                permissions.tag(3)
                goalSetup.tag(4)
                healthIssues.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Page 0 — Welcome

    private var welcome: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(LinearGradient(colors: [CarePlusPalette.careBlue,
                                                      CarePlusPalette.dietCoral,
                                                      CarePlusPalette.workoutPink],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Welcome to MyHealth").font(.largeTitle).bold()
            Text("Care · Diet · Train · Workout — your complete health companion. All on your device, plus optional clinical integration.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            primary("Get started") { withAnimation { page = 1 } }
        }
        .padding()
    }

    // MARK: - Page 1 — Login or guest

    private var loginOrGuest: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sign in or continue").font(.title2).bold()
                Text("Sign in to sync across devices, or continue as a guest. You can sync later.")
                    .font(.footnote).foregroundStyle(.secondary)

                grouped("Email") {
                    TextField("you@example.com", text: $email)
                        .textContentType(.emailAddress).autocapitalization(.none)
                }
                grouped("Password") {
                    SecureField("••••••••", text: $password)
                }

                Button {
                    Task {
                        await auth.login(email: email, password: password)
                        if auth.isAuthenticated { withAnimation { page = 2 } }
                    }
                } label: {
                    Text(auth.loading ? "Signing in…" : "Sign in").bold()
                        .frame(maxWidth: .infinity).padding()
                        .background(CarePlusPalette.careBlue,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }.disabled(email.isEmpty || password.count < 6 || auth.loading)

                Button {
                    auth.continueAsGuest()
                    withAnimation { page = 2 }
                } label: {
                    Text("Continue as guest").bold()
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                if let err = auth.errorMessage {
                    Text(err).font(.caption).foregroundStyle(CarePlusPalette.danger)
                }
            }
            .padding()
        }
    }

    // MARK: - Page 2 — Birth details

    private var birthDetails: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your birth details").font(.title2).bold()
                Text("Used for biological age, fertility window estimates, and (if you opt in) astro insights. Stored on this device.")
                    .font(.footnote).foregroundStyle(.secondary)

                grouped("Name") {
                    TextField("Your name", text: $name).textContentType(.name)
                }
                grouped("Date of birth") {
                    DatePicker("DOB", selection: $birthDate, displayedComponents: .date)
                        .labelsHidden()
                }
                grouped("Approximate time of birth") {
                    Picker("", selection: $birthTimeApprox) {
                        ForEach(["Morning","Afternoon","Evening","Night","Unknown"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }.pickerStyle(.segmented)
                }
                grouped("City of birth (optional)") {
                    TextField("e.g. Sunnyvale, CA", text: $birthLocation)
                }

                primary("Continue") {
                    UserDefaults.standard.set(name, forKey: "profile.name")
                    UserDefaults.standard.set(birthLocation, forKey: "profile.birthLocation")
                    withAnimation { page = 3 }
                }
                .disabled(name.isEmpty)
                .padding(.top, 12)
            }
            .padding()
        }
    }

    // MARK: - Page 3 — Permissions

    private var permissions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Permissions").font(.title2).bold()
                Text("Each is optional. Care+ works without any of them, but features improve with each grant.")
                    .font(.footnote).foregroundStyle(.secondary)

                permissionRow(
                    title: "Apple Health",
                    subtitle: "Steps, HR, sleep, weight. Read & write.",
                    symbol: "heart.text.square.fill",
                    granted: hkGranted
                ) {
                    Task {
                        await iOSHealthKitManager.shared.requestAuthorization()
                        hkGranted = HKHealthStore.isHealthDataAvailable()
                    }
                }
                permissionRow(
                    title: "MyChart (SMART-on-FHIR)",
                    subtitle: "Read your conditions, meds, labs.",
                    symbol: "cross.case.fill",
                    granted: fhirConnected
                ) { /* deferred — full connect lives on Care home */ fhirConnected = false }

                permissionRow(
                    title: "Notifications",
                    subtitle: "Reminders for meds + standup timer.",
                    symbol: "bell.fill",
                    granted: notifGranted
                ) {
                    Task {
                        let center = UNUserNotificationCenter.current()
                        if let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge]) {
                            notifGranted = granted
                        }
                    }
                }

                permissionRow(
                    title: "Location",
                    subtitle: "Doctor finder + run tracker.",
                    symbol: "location.fill",
                    granted: locationGranted
                ) {
                    LocationPermissionHelper.shared.request { granted in
                        locationGranted = granted
                    }
                }

                primary("Continue") { withAnimation { page = 4 } }
                    .padding(.top, 12)
            }
            .padding()
        }
    }

    private func permissionRow(title: String, subtitle: String, symbol: String,
                               granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(CarePlusPalette.careBlue.opacity(0.18), in: Circle())
                    .foregroundStyle(CarePlusPalette.careBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: granted ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(granted ? CarePlusPalette.success : .tertiary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page 4 — Goal

    private var goalSetup: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("What's your goal?").font(.title2).bold().padding(.horizontal)
            VStack(spacing: 8) {
                ForEach(HealthGoal.allCases) { g in
                    Button { goal = g } label: {
                        HStack {
                            Image(systemName: g.icon).foregroundStyle(CarePlusPalette.careBlue)
                            Text(g.label).font(.headline)
                            Spacer()
                            if goal == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(CarePlusPalette.careBlue)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            Spacer()
            primary("Continue") { withAnimation { page = 5 } }
                .padding(.horizontal)
        }
    }

    // MARK: - Page 5 — Health issues

    private var healthIssues: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Any conditions to declare?").font(.title2).bold()
                Text("Used to filter unsafe exercises and tune food suggestions. Stored only on this device.")
                    .font(.footnote).foregroundStyle(.secondary)

                ForEach(HealthCondition.allCases.filter { $0 != .none }) { c in
                    Toggle(isOn: Binding(
                        get: { hcStore.conditions.contains(c) },
                        set: { _ in hcStore.toggle(c) }
                    )) {
                        Label(c.label, systemImage: c.symbol)
                    }
                    .padding(.vertical, 4)
                }

                primary("Finish") {
                    if trialStartISO.isEmpty {
                        trialStartISO = ISO8601DateFormatter().string(from: Date())
                    }
                    didOnboard = true
                }
                .padding(.top, 12)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func grouped<Content: View>(_ label: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            content()
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).bold()
                .frame(maxWidth: .infinity).padding()
                .background(CarePlusPalette.careBlue,
                            in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - HealthGoal (kept here for backwards compat with rest of app)

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

// MARK: - Location permission helper

final class LocationPermissionHelper: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionHelper()
    private let manager = CLLocationManager()
    private var callback: ((Bool) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func request(callback: @escaping (Bool) -> Void) {
        self.callback = callback
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let granted = [.authorizedAlways, .authorizedWhenInUse]
            .contains(manager.authorizationStatus)
        callback?(granted)
        callback = nil
    }
}
