import SwiftUI
import FitFusionCore
import CoreData

/// Edit just the schedule + eat-when (color and identity fields stay fixed
/// after creation; full edit is via Add for v1).
struct MedicineRoutineView: View {
    let medicine: NSManagedObject
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var times: [MedicineReminderService.TimeOfDay] = []
    @State private var selectedWeekdays: Set<Int> = Set(1...7)
    @State private var eatWhen = "standalone"

    var body: some View {
        NavigationStack {
            Form {
                Section("Eat when") {
                    Picker("Eat when", selection: $eatWhen) {
                        Text("Standalone").tag("standalone")
                        Text("Before food").tag("before")
                        Text("With food").tag("with")
                        Text("After food").tag("after")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Times") {
                    ForEach(times.indices, id: \.self) { i in
                        DatePicker(
                            "Reminder \(i + 1)",
                            selection: Binding(
                                get: { dateFor(times[i]) },
                                set: { newDate in
                                    let comps = Calendar.current.dateComponents([.hour, .minute],
                                                                                from: newDate)
                                    times[i] = .init(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    .onDelete { idxs in times.remove(atOffsets: idxs) }
                    Button {
                        times.append(.init(hour: 12, minute: 0))
                    } label: {
                        Label("Add another time", systemImage: "plus.circle")
                    }
                }
                Section("Days") {
                    HStack(spacing: 4) {
                        ForEach(1...7, id: \.self) { day in
                            let label = ["S","M","T","W","T","F","S"][day - 1]
                            Button {
                                if selectedWeekdays.contains(day) {
                                    selectedWeekdays.remove(day)
                                } else {
                                    selectedWeekdays.insert(day)
                                }
                            } label: {
                                Text(label)
                                    .font(.caption.bold())
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle().fill(
                                            selectedWeekdays.contains(day) ? Color.indigo : Color.gray.opacity(0.2)
                                        )
                                    )
                                    .foregroundStyle(selectedWeekdays.contains(day) ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Edit routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        let s = MedicineReminderService.decodeSchedule(
            medicine.value(forKey: "scheduleJSON") as? String
        )
        times = s.times
        selectedWeekdays = s.weekdays
        eatWhen = (medicine.value(forKey: "eatWhen") as? String) ?? "standalone"
    }

    private func save() {
        let s = MedicineReminderService.Schedule(times: times, weekdays: selectedWeekdays)
        medicine.setValue(MedicineReminderService.encodeSchedule(s), forKey: "scheduleJSON")
        medicine.setValue(eatWhen, forKey: "eatWhen")
        CloudStore.shared.save()
        onSaved()
        dismiss()
    }

    private func dateFor(_ t: MedicineReminderService.TimeOfDay) -> Date {
        var c = DateComponents(); c.hour = t.hour; c.minute = t.minute
        return Calendar.current.date(from: c) ?? Date()
    }
}
