import SwiftUI
import PocketCore

struct BedtimeView: View {
    @State private var bedtime = DateComponents(calendar: .current, hour: 22, minute: 0).date ?? Date()
    @State private var wake    = DateComponents(calendar: .current, hour: 6, minute: 30).date ?? Date()

    var body: some View {
        Form {
            DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
            DatePicker("Wake",    selection: $wake,    displayedComponents: .hourAndMinute)
            Section {
                let h = sleepHours
                Text(String(format: "%.1f hours of sleep", h))
                    .font(.headline)
                    .foregroundColor(h >= 7 ? .green : .orange)
            }
        }
        .navigationTitle("Bedtime")
    }

    private var sleepHours: Double {
        let cal = Calendar.current
        let b = cal.dateComponents([.hour, .minute], from: bedtime)
        let w = cal.dateComponents([.hour, .minute], from: wake)
        return BedtimeEngine.sleepHours(bedtime: (b.hour ?? 0, b.minute ?? 0),
                                        wake: (w.hour ?? 0, w.minute ?? 0))
    }
}
