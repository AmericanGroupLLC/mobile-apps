import SwiftUI
import FitFusionCore
import CoreData

/// "Activities" \u{2014} lightweight non-workout movement (walking, gardening,
/// cycling around town\u{2026}). Distinct from `WorkoutPlan`/`ExerciseLog` which
/// are intentional training sessions.
struct ActivityListView: View {
    @State private var activities: [NSManagedObject] = []
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if activities.isEmpty {
                    ContentUnavailableView(
                        "No activities logged yet",
                        systemImage: "figure.walk.motion",
                        description: Text("Walking the dog? Cleaning? Tap + to log it.")
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(activities, id: \.objectID) { a in
                        NavigationLink {
                            ActivityDetailView(activity: a) { reload() }
                        } label: {
                            ActivityRow(activity: a)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Activities")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddActivityView { reload() }
        }
        .task { reload() }
    }

    private func reload() {
        activities = CloudStore.shared.fetchActivities(daysBack: 90)
    }
}

private struct ActivityRow: View {
    let activity: NSManagedObject

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: kind))
                .font(.title3.bold())
                .frame(width: 44, height: 44)
                .background(.green.opacity(0.18), in: Circle())
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.capitalized).font(.headline)
                Text("\(Int(duration)) min \u{00b7} \(Int(kcal)) kcal")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(performedAt.formatted(.relative(presentation: .named)))
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var kind: String { (activity.value(forKey: "kind") as? String) ?? "activity" }
    private var duration: Double { (activity.value(forKey: "durationMin") as? Double) ?? 0 }
    private var kcal: Double { (activity.value(forKey: "kcalBurned") as? Double) ?? 0 }
    private var performedAt: Date { (activity.value(forKey: "performedAt") as? Date) ?? Date() }

    private func icon(for kind: String) -> String {
        switch kind.lowercased() {
        case "walking", "walk":     return "figure.walk"
        case "running", "run":       return "figure.run"
        case "cycling", "biking":    return "bicycle"
        case "swimming":             return "figure.pool.swim"
        case "yoga":                 return "figure.mind.and.body"
        case "gardening":            return "leaf.fill"
        case "cleaning", "chores":   return "sparkles"
        case "stairs":               return "stairs"
        default:                     return "figure.walk.motion"
        }
    }
}
