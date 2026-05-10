import Foundation
import UserNotifications
import DriftCore

/// Push registration + foreground/notification-tap delegate.
final class PushService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushService()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let kind = response.notification.request.content.userInfo["type"] as? String ?? "match"
        let push: AnalyticsEvent.PushType = kind == "message" ? .message : .match
        AnalyticsService.shared.track(.appOpenedFromPush(pushType: push))
        handler()
    }
}
