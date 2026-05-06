import Foundation
import Combine
import DriftCore

@MainActor
final class SettingsModel: ObservableObject {
    static let shared = SettingsModel()

    @Published var analyticsOptedIn: Bool = false {
        didSet {
            AnalyticsService.shared.optedIn = analyticsOptedIn
            UserDefaults.standard.set(analyticsOptedIn, forKey: "drift.analytics.opt_in")
            AnalyticsService.shared.track(.settingsToggled(name: "analytics", enabled: analyticsOptedIn))
        }
    }
    @Published var crashOptedIn: Bool = false {
        didSet {
            CrashReportingService.shared.optedIn = crashOptedIn
            UserDefaults.standard.set(crashOptedIn, forKey: "drift.crash.opt_in")
        }
    }
    @Published var invisible: Bool = false
    @Published var paused:    Bool = false
    @Published var preferred12HourClock: Bool = true
    @Published var theme: AppTheme = .system

    enum AppTheme: String { case system, light, dark }

    private init() {
        analyticsOptedIn = UserDefaults.standard.bool(forKey: "drift.analytics.opt_in")
        crashOptedIn     = UserDefaults.standard.bool(forKey: "drift.crash.opt_in")
    }
}
