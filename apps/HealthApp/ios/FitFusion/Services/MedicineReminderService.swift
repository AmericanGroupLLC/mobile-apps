import Foundation
import UserNotifications
import FitFusionCore

/// Schedules per-dose local notifications for medicines using
/// `UNUserNotificationCenter`. No internet needed; works offline; survives
/// reboots; respects per-medicine schedule (cron-like rules stored as JSON
/// inside `MedicineEntity.scheduleJSON`).
///
/// Notification category `MEDICINE_REMINDER` includes two actions:
///  - **Take**: writes a `MedicineDoseLogEntity(takenAt: now)` immediately.
///  - **Snooze 10 min**: re-schedules the same fire 10 minutes later.
///
/// Both actions are handled by the app delegate's
/// `userNotificationCenter(_:didReceive:withCompletionHandler:)`.
@MainActor
public final class MedicineReminderService: NSObject, ObservableObject {

    public static let shared = MedicineReminderService()

    private static let category = "MEDICINE_REMINDER"
    private static let snoozeMinutes = 10

    // MARK: - Bootstrap

    public func bootstrap() {
        let take = UNNotificationAction(
            identifier: "MED_TAKE",
            title: "Take",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(
            identifier: "MED_SNOOZE",
            title: "Snooze 10 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.category,
            actions: [take, snooze],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
    }

    public func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Best-effort; the app still works without reminders.
        }
    }

    // MARK: - Schedule shape (JSON-encoded inside MedicineEntity.scheduleJSON)

    /// Simple recurring schedule: a list of times-of-day, with a weekday filter.
    /// Times are in the user's local timezone.
    public struct Schedule: Codable, Hashable {
        public var times: [TimeOfDay]
        public var weekdays: Set<Int>   // 1 = Sunday, 7 = Saturday
        public var startISO: String?
        public var endISO: String?

        public init(times: [TimeOfDay] = [.init(hour: 9, minute: 0)],
                    weekdays: Set<Int> = Set(1...7),
                    startISO: String? = nil,
                    endISO: String? = nil) {
            self.times = times
            self.weekdays = weekdays
            self.startISO = startISO
            self.endISO = endISO
        }
    }

    public struct TimeOfDay: Codable, Hashable, Identifiable {
        public var hour: Int
        public var minute: Int
        public var id: String { "\(hour):\(minute)" }

        public init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }
    }

    public static func encodeSchedule(_ s: Schedule) -> String {
        guard let data = try? JSONEncoder().encode(s),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    public static func decodeSchedule(_ s: String?) -> Schedule {
        guard let s, let data = s.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Schedule.self, from: data) else {
            return Schedule()
        }
        return decoded
    }

    // MARK: - Scheduling per medicine

    public func reschedule(medicineId: UUID, name: String, dosage: String,
                           schedule: Schedule) async {
        await cancel(medicineId: medicineId)
        let center = UNUserNotificationCenter.current()
        for time in schedule.times {
            for weekday in schedule.weekdays {
                let content = UNMutableNotificationContent()
                content.title = "Time for \(name)"
                content.body = dosage.isEmpty ? "Tap to mark as taken." : "\(dosage) \u{00b7} tap to mark as taken."
                content.categoryIdentifier = Self.category
                content.userInfo = [
                    "medicineId": medicineId.uuidString,
                    "name": name,
                    "dosage": dosage,
                ]
                content.sound = .default

                var components = DateComponents()
                components.weekday = weekday
                components.hour = time.hour
                components.minute = time.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

                let id = "\(medicineId.uuidString)-\(weekday)-\(time.hour)-\(time.minute)"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                do { try await center.add(req) } catch { /* skip */ }
            }
        }
    }

    public func cancel(medicineId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toCancel = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(medicineId.uuidString) }
        center.removePendingNotificationRequests(withIdentifiers: toCancel)
    }

    public func pendingCount(for medicineId: UUID) async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix(medicineId.uuidString) }.count
    }

    /// Reschedule every active medicine. Call from app start to recover from
    /// notification list resets after a reboot or auth toggle.
    public func resyncAll() async {
        let medicines = CloudStore.shared.fetchMedicines()
        for med in medicines {
            guard let id = med.value(forKey: "id") as? UUID,
                  let name = med.value(forKey: "name") as? String else { continue }
            let dosage = (med.value(forKey: "dosage") as? String) ?? ""
            let schedule = Self.decodeSchedule(med.value(forKey: "scheduleJSON") as? String)
            await reschedule(medicineId: id, name: name, dosage: dosage, schedule: schedule)
        }
    }

    // MARK: - Take / snooze handling

    func handleAction(_ identifier: String, userInfo: [AnyHashable: Any]) async {
        guard let medicineIdStr = userInfo["medicineId"] as? String,
              let medicineId = UUID(uuidString: medicineIdStr) else { return }

        switch identifier {
        case "MED_TAKE", UNNotificationDefaultActionIdentifier:
            CloudStore.shared.logDose(medicineId: medicineId,
                                      scheduledFor: Date(),
                                      takenAt: Date())
        case "MED_SNOOZE":
            let content = UNMutableNotificationContent()
            content.title = (userInfo["name"] as? String).map { "Snoozed: \($0)" } ?? "Snoozed reminder"
            content.body = (userInfo["dosage"] as? String) ?? "Tap to mark as taken."
            content.categoryIdentifier = Self.category
            content.userInfo = userInfo
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(Self.snoozeMinutes * 60),
                                                             repeats: false)
            let req = UNNotificationRequest(
                identifier: "\(medicineId.uuidString)-snooze-\(Date().timeIntervalSince1970)",
                content: content, trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(req)
            CloudStore.shared.logDose(medicineId: medicineId,
                                      scheduledFor: Date(),
                                      snoozedAt: Date())
        default:
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension MedicineReminderService: UNUserNotificationCenterDelegate {
    nonisolated public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                                   willPresent notification: UNNotification,
                                                   withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                                   didReceive response: UNNotificationResponse,
                                                   withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.actionIdentifier
        let info = response.notification.request.content.userInfo
        Task { @MainActor in
            await MedicineReminderService.shared.handleAction(id, userInfo: info)
            completionHandler()
        }
    }
}
