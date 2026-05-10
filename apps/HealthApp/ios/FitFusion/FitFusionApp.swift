import SwiftUI
import BackgroundTasks
import FitFusionCore

@main
struct FitFusionApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var hk = iOSHealthKitManager.shared
    @StateObject private var cloud = CloudStore.shared
    @StateObject private var bridge = WatchBridge.shared
    @StateObject private var mirror = WorkoutMirrorReceiver.shared
    @StateObject private var vitals = VitalsService.shared
    @StateObject private var meds = MedicineReminderService.shared
    @StateObject private var crash = CrashReportingService.shared
    @StateObject private var analytics = AnalyticsService.shared

    init() {
        // UI-test entrypoint: when the bundle is launched with -resetState
        // (only the XCUITest target ever passes this), wipe local state so
        // tests always start at the Login screen with no ambient onboarding.
        if ProcessInfo.processInfo.arguments.contains("-resetState") {
            UserDefaults.standard.removeObject(forKey: AuthStore.didOnboardKey)
            UserDefaults.standard.removeObject(forKey: "isGuest")
            UserDefaults.standard.removeObject(forKey: "user")
            UserDefaults.standard.removeObject(forKey: "token")
        }

        // Crash reporting — opt-in via Settings + DSN must be configured.
        // No-op when either is absent. Privacy stays first.
        let release = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        CrashReportingService.shared.bootstrapIfEnabled(
            release: "MyHealth-iOS@\(release)"
        )
        // Product analytics — same opt-in pattern, separate API key.
        AnalyticsService.shared.bootstrapIfEnabled()

        // Register the nightly on-device fine-tune task. Identifier must
        // match `Info.plist`'s `BGTaskSchedulerPermittedIdentifiers`.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: PersonalFineTuner.backgroundTaskIdentifier,
            using: nil
        ) { task in
            Task {
                let ok = await PersonalFineTuner.shared.fineTune(samples: [])
                task.setTaskCompleted(success: ok)
                PersonalFineTuner.shared.scheduleNextRun()
            }
        }
        // Wire notification categories + delegate before any reminder fires.
        MedicineReminderService.shared.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(hk)
                .environmentObject(cloud)
                .environmentObject(bridge)
                .environmentObject(mirror)
                .environmentObject(vitals)
                .environmentObject(meds)
                .tint(.orange)
                .task {
                    // Boot the AdaptivePlanner so first call is warm.
                    _ = AdaptivePlanner.shared
                    if auth.isAuthenticated {
                        // HealthKit only matters for non-guest *or* guest who
                        // wants vitals. Guests can decline freely.
                        await hk.requestAuthorization()
                        await vitals.refresh()
                        await meds.requestAuthorization()
                        await meds.resyncAll()
                    }
                    mirror.startObserving()
                    PersonalFineTuner.shared.scheduleNextRun()
                }
        }
    }
}
