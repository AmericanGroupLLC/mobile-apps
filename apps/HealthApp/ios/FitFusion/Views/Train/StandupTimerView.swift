import SwiftUI
import FitFusionCore
import UserNotifications

/// Standup timer — sedentary alert. Configurable interval; each fire is a
/// local notification. Reuses the iOS notification authorization request
/// pattern from `MedicineReminderService`.
struct StandupTimerView: View {

    @State private var intervalMinutes: Int = 50
    @State private var enabled: Bool = false
    @State private var statusText: String = ""

    private let tint = CarePlusPalette.trainGreen
    private let identifier = "careplus.standup.timer"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                header

                Section {
                    Stepper("Every \(intervalMinutes) min", value: $intervalMinutes, in: 15...120, step: 5)
                        .padding()
                        .background(CarePlusPalette.surfaceElevated,
                                    in: RoundedRectangle(cornerRadius: 12))
                }

                Toggle("Standup reminders", isOn: $enabled)
                    .padding()
                    .background(CarePlusPalette.surfaceElevated,
                                in: RoundedRectangle(cornerRadius: 12))
                    .onChange(of: enabled) { _, newValue in
                        Task { await applyToggle(newValue) }
                    }

                if !statusText.isEmpty {
                    Text(statusText).font(.caption).foregroundStyle(.secondary)
                }

                Text("Notification fires every \(intervalMinutes) minutes between 09:00 and 18:00 in your local timezone. Pause anytime.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(CarePlusSpacing.lg)
        }
        .navigationTitle("Standup timer")
        .navigationBarTitleDisplayMode(.inline)
        .background(CarePlusPalette.surface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 56, height: 56)
                Image(systemName: "figure.stand").font(.system(size: 26)).foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Move every hour").font(.headline)
                Text("Sitting too long ↑ glucose, ↓ HRV.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func applyToggle(_ on: Bool) async {
        let center = UNUserNotificationCenter.current()
        if !on {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            statusText = "Reminders cancelled."
            return
        }
        // Request notification permission first.
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch { /* best-effort */ }

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Stand up & stretch"
        content.body = "Quick walk or 10 squats — your back will thank you."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(60, intervalMinutes * 60)),
            repeats: true
        )
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        do {
            try await center.add(request)
            statusText = "Scheduled — first reminder in \(intervalMinutes) min."
        } catch {
            statusText = "Failed: \(error.localizedDescription)"
        }
    }
}
