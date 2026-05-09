import SwiftUI
import FitFusionCore

struct WorkoutDetailView: View {
    let template: WorkoutTemplate
    @State private var showSchedule = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero

                Text(template.summary)
                    .font(.body)

                HStack(spacing: 12) {
                    infoTile(title: "Duration", value: "\(template.durationMin) min")
                    infoTile(title: "Level", value: template.level.label)
                    infoTile(title: "Type", value: template.category.label)
                }

                Button {
                    showSchedule = true
                } label: {
                    Label("Send to Watch", systemImage: "applewatch")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.orange, .pink],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .navigationTitle(template.name)
        .sheet(isPresented: $showSchedule) {
            ScheduleToWatchSheet(template: template)
                .presentationDetents([.medium])
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.orange, .pink, .purple],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text(template.category.label.uppercased())
                    .font(.caption2).bold()
                    .foregroundStyle(.white.opacity(0.85))
                Text(template.name)
                    .font(.title).bold()
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).bold()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
