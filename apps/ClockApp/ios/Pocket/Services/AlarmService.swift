import Foundation
import UserNotifications
import PocketCore

final class AlarmService {
    static let shared = AlarmService()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func schedule(_ alarm: Alarm) async {
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.sound = .default

        if alarm.repeatOn.isEmpty {
            var c = DateComponents()
            c.hour = alarm.hour; c.minute = alarm.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: false)
            let req = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            try? await center.add(req)
        } else {
            for w in alarm.repeatOn {
                var c = DateComponents()
                c.hour = alarm.hour; c.minute = alarm.minute; c.weekday = w.rawValue
                let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
                let id = "\(alarm.id.uuidString)-\(w.rawValue)"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(req)
            }
        }
    }

    func cancel(_ alarm: Alarm) {
        let ids = (alarm.repeatOn.isEmpty
                   ? [alarm.id.uuidString]
                   : alarm.repeatOn.map { "\(alarm.id.uuidString)-\($0.rawValue)" })
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
