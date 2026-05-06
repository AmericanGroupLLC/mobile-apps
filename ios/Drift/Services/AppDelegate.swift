import SwiftUI
import UIKit
import DriftCore
import UserNotifications

/// Bootstraps notification config + Sentry + PostHog conditionally.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = PushService.shared

        let env = ProcessInfo.processInfo.environment

        #if canImport(PostHog)
        if let key = env["POSTHOG_API_KEY"], !key.isEmpty {
            AnalyticsService.shared.usePostHog(
                apiKey: key,
                host: env["POSTHOG_HOST"] ?? "https://us.i.posthog.com"
            )
        }
        #endif

        #if canImport(Sentry)
        if let dsn = env["SENTRY_DSN"], !dsn.isEmpty {
            CrashReportingService.shared.useSentry(dsn: dsn)
        }
        #endif

        AnalyticsService.shared.optedIn      = SettingsModel.shared.analyticsOptedIn
        CrashReportingService.shared.optedIn = SettingsModel.shared.crashOptedIn

        return true
    }
}
