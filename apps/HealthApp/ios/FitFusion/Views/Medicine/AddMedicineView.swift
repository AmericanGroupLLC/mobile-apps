import SwiftUI
import FitFusionCore
import CoreData

/// Add-medicine sheet. Three pages collapsed into one form: identity, dosing,
/// schedule. Saving creates a `MedicineEntity` AND immediately schedules its
/// notifications via `MedicineReminderService`.
struct AddMedicineView: View {
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dosage = "1 tablet"
    @State private var unit = "tablet"
    @State private var manufacturer = ""
    @State private var price: Double = 0
    @State private var criticalLevel = "low"
    @State private var eatWhen = "standalone"
    @State private var colorHex = "#5B8DEF"
    @State private var notes = ""

    @State private var times: [MedicineReminderService.TimeOfDay] = [
        .init(hour: 9, minute: 0)
    ]
    @State private var selectedWeekdays: Set<Int> = Set(1...7)

    private let palette = ["#5B8DEF", "#F75A89", "#34C759", "#FF9500", "#AF52DE", "#FFD60A"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Medicine") {
                    TextField("Name (e.g. Vitamin D)", text: $name)
                        .textInputAutocapitalization(.words)
                    HStack {
                        TextField("Dosage", text: $dosage)
                        Picker("Unit", selection: $unit) {
                            Text("tablet").tag("tablet")
                            Text("mg").tag("mg")
                            Text("ml").tag("ml")
                            Text("IU").tag("IU")
                            Text("capsule").tag("capsule")
                            Text("drop").tag("drop")
                        }
                        .pickerStyle(.menu)
                    }
                    TextField("Manufacturer", text: $manufacturer)
                    Stepper("Price: \(String(format: "$%.2f", price))",
                            value: $price, in: 0...10000, step: 0.5)
                }

                Section("Care") {
                    Picker("Criticality", selection: $criticalLevel) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    Picker("Eat when", selection: $eatWhen) {
                        Text("Standalone").tag("standalone")
                        Text("Before food").tag("before")
                        Text("With food").tag("with")
                        Text("After food").tag("after")
                    }
                    HStack {
                        Text("Color")
                        Spacer()
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().strokeBorder(.primary,
                                                          lineWidth: colorHex == hex ? 2 : 0)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
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
                        times.append(.init(hour: 21, minute: 0))
                    } label: {
                        Label("Add another time", systemImage: "plus.circle")
                    }
                }

                Section("Days of the week") {
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

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || times.isEmpty || selectedWeekdays.isEmpty)
                }
            }
        }
    }

    private func dateFor(_ t: MedicineReminderService.TimeOfDay) -> Date {
        var c = DateComponents()
        c.hour = t.hour
        c.minute = t.minute
        return Calendar.current.date(from: c) ?? Date()
    }

    private func save() async {
        let schedule = MedicineReminderService.Schedule(
            times: times,
            weekdays: selectedWeekdays
        )
        let scheduleJSON = MedicineReminderService.encodeSchedule(schedule)
        let entity = CloudStore.shared.addMedicine(
            name: name,
            dosage: dosage,
            unit: unit,
            manufacturer: manufacturer.isEmpty ? nil : manufacturer,
            priceCents: Int(price * 100),
            criticalLevel: criticalLevel,
            eatWhen: eatWhen,
            scheduleJSON: scheduleJSON,
            colorHex: colorHex,
            notes: notes.isEmpty ? nil : notes
        )
        if let entity, let id = entity.value(forKey: "id") as? UUID {
            await MedicineReminderService.shared.reschedule(
                medicineId: id,
                name: name,
                dosage: dosage,
                schedule: schedule
            )
        }
        onCreated()
        dismiss()
    }
}
