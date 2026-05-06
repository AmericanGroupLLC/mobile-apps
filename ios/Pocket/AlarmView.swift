import SwiftUI

struct Alarm: Identifiable {
    let id = UUID()
    var time: Date
    var enabled: Bool
}

struct AlarmView: View {
    @State private var alarms: [Alarm] = []
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach($alarms) { $alarm in
                    HStack {
                        Text(alarm.time, style: .time)
                            .font(.title2)
                        Spacer()
                        Toggle("", isOn: $alarm.enabled).labelsHidden()
                    }
                }
                .onDelete { alarms.remove(atOffsets: $0) }
            }
            .navigationTitle("Alarm")
            .toolbar {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showingAdd) {
                AddAlarmSheet { alarms.append(Alarm(time: $0, enabled: true)) }
            }
        }
    }
}

struct AddAlarmSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()
    let onSave: (Date) -> Void

    var body: some View {
        NavigationStack {
            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { onSave(time); dismiss() }
                    }
                }
        }
    }
}
