import SwiftUI
import FitFusionCore
import CoreData

/// List of all active medicines with an inline "today's progress" line and
/// a + button to add a new one. Tap a row to drill into `MedicineDetailView`.
struct MedicineListView: View {
    @State private var medicines: [NSManagedObject] = []
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if medicines.isEmpty {
                    ContentUnavailableView(
                        "No medicines yet",
                        systemImage: "pills",
                        description: Text("Add your first medicine to get gentle reminders at the right time.")
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(medicines, id: \.objectID) { m in
                        NavigationLink {
                            MedicineDetailView(medicine: m) { reload() }
                        } label: {
                            MedicineRow(medicine: m)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Medicines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddMedicineView { reload() }
        }
        .task { reload() }
    }

    private func reload() {
        medicines = CloudStore.shared.fetchMedicines()
    }
}

struct MedicineRow: View {
    let medicine: NSManagedObject

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color)
                    .frame(width: 44, height: 44)
                Image(systemName: "pills.fill")
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text((medicine.value(forKey: "name") as? String) ?? "Medicine")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text((medicine.value(forKey: "dosage") as? String) ?? "—")
                        .font(.caption.weight(.semibold))
                    Text("·").foregroundStyle(.secondary)
                    Text((medicine.value(forKey: "eatWhen") as? String)?.replacingOccurrences(of: "_", with: " ") ?? "anytime")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Text(scheduleSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if criticalLevel == "high" {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var color: Color {
        let hex = (medicine.value(forKey: "colorHex") as? String) ?? "#5B8DEF"
        return Color(hex: hex) ?? .blue
    }
    private var criticalLevel: String {
        (medicine.value(forKey: "criticalLevel") as? String) ?? "low"
    }
    private var scheduleSummary: String {
        let s = MedicineReminderService.decodeSchedule(medicine.value(forKey: "scheduleJSON") as? String)
        let timeStrings = s.times.map { String(format: "%02d:%02d", $0.hour, $0.minute) }
        return timeStrings.joined(separator: ", ")
    }
}

extension Color {
    init?(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6, let v = UInt32(trimmed, radix: 16) else { return nil }
        self = Color(red: Double((v >> 16) & 0xFF) / 255,
                     green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255)
    }
}
