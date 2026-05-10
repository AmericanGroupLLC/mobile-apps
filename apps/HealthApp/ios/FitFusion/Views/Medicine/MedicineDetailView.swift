import SwiftUI
import FitFusionCore
import CoreData

/// Medicine detail with adherence streak (last 14 days) and an "I took it now"
/// button so the user can log out-of-band doses (e.g. they took it but the
/// reminder hadn't fired yet).
struct MedicineDetailView: View {
    let medicine: NSManagedObject
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var doseLogs: [NSManagedObject] = []
    @State private var showRoutineEditor = false
    @State private var showArchiveConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                routineCard
                adherenceCard
                actions
            }
            .padding()
        }
        .navigationTitle((medicine.value(forKey: "name") as? String) ?? "Medicine")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRoutineEditor) {
            MedicineRoutineView(medicine: medicine) {
                Task {
                    if let id = medicine.value(forKey: "id") as? UUID,
                       let name = medicine.value(forKey: "name") as? String {
                        let dosage = (medicine.value(forKey: "dosage") as? String) ?? ""
                        let s = MedicineReminderService.decodeSchedule(medicine.value(forKey: "scheduleJSON") as? String)
                        await MedicineReminderService.shared.reschedule(
                            medicineId: id, name: name, dosage: dosage, schedule: s
                        )
                    }
                    onChange()
                }
            }
        }
        .alert("Archive medicine?", isPresented: $showArchiveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Archive", role: .destructive) {
                Task {
                    if let id = medicine.value(forKey: "id") as? UUID {
                        await MedicineReminderService.shared.cancel(medicineId: id)
                    }
                    CloudStore.shared.archiveMedicine(medicine)
                    onChange()
                    dismiss()
                }
            }
        } message: {
            Text("Reminders will be cancelled and the medicine moved out of your active list. History is preserved.")
        }
        .task { reload() }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color).frame(width: 64, height: 64)
                Image(systemName: "pills.fill").foregroundStyle(.white).font(.title)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text((medicine.value(forKey: "dosage") as? String) ?? "")
                    .font(.headline)
                Text((medicine.value(forKey: "manufacturer") as? String) ?? "Generic")
                    .font(.caption2).foregroundStyle(.secondary)
                if let level = medicine.value(forKey: "criticalLevel") as? String {
                    Text(level.capitalized)
                        .font(.caption2.bold())
                        .foregroundStyle(level == "high" ? .red : (level == "medium" ? .orange : .green))
                }
            }
            Spacer()
        }
    }

    private var routineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Routine").font(.headline)
                Spacer()
                Button("Edit") { showRoutineEditor = true }
                    .font(.caption.bold())
            }
            let s = MedicineReminderService.decodeSchedule(
                medicine.value(forKey: "scheduleJSON") as? String
            )
            ForEach(s.times) { t in
                HStack {
                    Image(systemName: "alarm.fill").foregroundStyle(.indigo)
                    Text(String(format: "%02d:%02d", t.hour, t.minute))
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(weekdayLabels(s.weekdays))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text("Take \(eatWhenLabel((medicine.value(forKey: "eatWhen") as? String) ?? "standalone"))")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var adherenceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 14 days").font(.headline)
            let last14 = lastNDays(14)
            HStack(spacing: 4) {
                ForEach(last14, id: \.self) { day in
                    let took = doseLogs.contains { log in
                        guard let scheduled = log.value(forKey: "scheduledFor") as? Date else { return false }
                        return Calendar.current.isDate(scheduled, inSameDayAs: day)
                            && (log.value(forKey: "takenAt") != nil || log.value(forKey: "snoozedAt") != nil)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(took ? Color.green : Color.gray.opacity(0.2))
                        .frame(height: 32)
                }
            }
            HStack {
                Text("\(streak()) day streak").font(.caption.weight(.semibold))
                Spacer()
                Text("\(takenCount()) of \(last14.count) taken")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                if let id = medicine.value(forKey: "id") as? UUID {
                    CloudStore.shared.logDose(medicineId: id, scheduledFor: Date(), takenAt: Date())
                    reload()
                }
            } label: {
                Label("I took it now", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            Button(role: .destructive) {
                showArchiveConfirm = true
            } label: {
                Label("Archive medicine", systemImage: "archivebox.fill")
                    .frame(maxWidth: .infinity).padding()
                    .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - helpers

    private var color: Color {
        Color(hex: (medicine.value(forKey: "colorHex") as? String) ?? "#5B8DEF") ?? .blue
    }

    private func reload() {
        if let id = medicine.value(forKey: "id") as? UUID {
            doseLogs = CloudStore.shared.recentDoseLogs(for: id, limit: 60)
        }
    }
    private func lastNDays(_ n: Int) -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<n).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }
    private func takenCount() -> Int {
        let last14 = lastNDays(14)
        return last14.filter { day in
            doseLogs.contains { log in
                guard let scheduled = log.value(forKey: "scheduledFor") as? Date else { return false }
                return Calendar.current.isDate(scheduled, inSameDayAs: day)
                    && log.value(forKey: "takenAt") != nil
            }
        }.count
    }
    private func streak() -> Int {
        var streak = 0
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        while doseLogs.contains(where: { log in
            guard let scheduled = log.value(forKey: "scheduledFor") as? Date else { return false }
            return cal.isDate(scheduled, inSameDayAs: day)
                && log.value(forKey: "takenAt") != nil
        }) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
    private func eatWhenLabel(_ raw: String) -> String {
        switch raw {
        case "before": return "before food"
        case "after": return "after food"
        case "with": return "with food"
        default: return "anytime"
        }
    }
    private func weekdayLabels(_ days: Set<Int>) -> String {
        if days.count == 7 { return "Daily" }
        let names = ["S", "M", "T", "W", "T", "F", "S"]
        return days.sorted().map { names[$0 - 1] }.joined(separator: " ")
    }
}
