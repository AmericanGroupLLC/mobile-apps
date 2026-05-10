import SwiftUI
import FitFusionCore

struct ScheduleToWatchSheet: View {
    let template: WorkoutTemplate
    @EnvironmentObject var cloud: CloudStore
    @EnvironmentObject var bridge: WatchBridge
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date().addingTimeInterval(60 * 30)
    @State private var notes = ""
    @State private var status: String?
    @State private var working = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Schedule") {
                    DatePicker("When", selection: $date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Button {
                        Task { await schedule() }
                    } label: {
                        HStack {
                            if working { ProgressView().controlSize(.small) }
                            Label("Send to Watch", systemImage: "applewatch")
                        }.frame(maxWidth: .infinity)
                    }
                    .disabled(working)
                }
                if let s = status {
                    Section { Text(s).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle(template.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func schedule() async {
        working = true; status = nil
        defer { working = false }

        // 1) Persist to CloudKit-synced Core Data
        cloud.addWorkoutPlan(templateId: template.id, scheduledFor: date,
                             notes: notes.isEmpty ? nil : notes)

        // 2) Push to the Watch via WCSession (today's plan IDs)
        let todayIds = cloud.fetchTodayPlans()
            .compactMap { $0.value(forKey: "templateId") as? String }
        bridge.push(todayPlanIds: todayIds)

        // 3) Schedule via WorkoutKit if available
        await WorkoutScheduler.shared.schedule(template: template, at: date)

        status = "✓ Scheduled & sent to Watch"
    }
}
