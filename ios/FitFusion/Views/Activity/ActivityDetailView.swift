import SwiftUI
import FitFusionCore
import CoreData

/// Read-only detail for a logged activity, with a delete affordance.
struct ActivityDetailView: View {
    let activity: NSManagedObject
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Activity") {
                    Text((activity.value(forKey: "kind") as? String)?.capitalized ?? "—")
                }
                LabeledContent("Duration") {
                    Text("\(Int((activity.value(forKey: "durationMin") as? Double) ?? 0)) min")
                }
                LabeledContent("Calories") {
                    Text("\(Int((activity.value(forKey: "kcalBurned") as? Double) ?? 0)) kcal")
                }
                LabeledContent("When") {
                    Text(((activity.value(forKey: "performedAt") as? Date) ?? Date())
                            .formatted(date: .abbreviated, time: .shortened))
                }
            }
            if let notes = activity.value(forKey: "notes") as? String, !notes.isEmpty {
                Section("Notes") { Text(notes) }
            }
            Section {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this activity?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                CloudStore.shared.viewContext.delete(activity)
                CloudStore.shared.save()
                onChange()
                dismiss()
            }
        }
    }
}
