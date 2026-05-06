import Foundation
import UserNotifications
import CardCore

/// `UNUserNotificationCenter` wrapper that schedules / cancels per-card.
/// The `cardId.uuidString` is the notification request identifier so cancels
/// and re-schedules are idempotent.
final class ReminderService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderService()

    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func schedule(card: Card, at fireTime: Date, surface: Surface) {
        guard let nextFire = ReminderScheduler.nextFireTime(for: fireTime) else { return }
        cancel(cardId: card.id)

        let content = UNMutableNotificationContent()
        content.title = "Card"
        content.body = card.text
        content.sound = .default
        content.userInfo = ["cardId": card.id.uuidString]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextFire
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: card.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { _ in }

        let delayMin = max(0, Int(nextFire.timeIntervalSince(Date()) / 60))
        AnalyticsService.shared.track(.reminderScheduled(surface: surface, delayMinutes: delayMin))
    }

    func cancel(cardId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [cardId.uuidString])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        AnalyticsService.shared.track(.reminderFired(surface: .app))
        completionHandler([.banner, .sound, .badge])
    }
}
