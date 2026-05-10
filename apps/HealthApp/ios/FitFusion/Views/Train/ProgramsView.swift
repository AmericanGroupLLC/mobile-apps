import SwiftUI
import FitFusionCore

/// List of pre-built programs (Push/Pull/Legs, Upper/Lower, Full Body, Beginner Strength).
struct ProgramsView: View {
    var body: some View {
        List(WorkoutPrograms.all) { program in
            NavigationLink { ProgramDetailView(program: program) } label: {
                ProgramRow(program: program)
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("Programs")
    }
}

struct ProgramRow: View {
    let program: WorkoutProgram

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                LinearGradient(colors: [.indigo, .purple],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("\(program.daysPerWeek)\u{00d7}")
                    .font(.title3.bold()).foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(program.name).font(.subheadline.bold())
                Text(program.split).font(.caption2).foregroundStyle(.secondary)
                Text("\(program.weeks) weeks \u{00b7} \(program.level.label)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ProgramDetailView: View {
    let program: WorkoutProgram

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                Text(program.summary).font(.body)
                ForEach(program.days) { day in
                    DayCard(day: day)
                }
            }
            .padding()
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.indigo, .purple, .pink],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text(program.split.uppercased())
                    .font(.caption2.bold()).foregroundStyle(.white.opacity(0.85))
                Text(program.name).font(.title2.bold()).foregroundStyle(.white)
                Text("\(program.weeks) weeks \u{00b7} \(program.daysPerWeek)\u{00d7} / wk \u{00b7} \(program.level.label)")
                    .font(.caption).foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
    }
}

private struct DayCard: View {
    let day: ProgramDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.name).font(.headline)
            Text("\(day.sets) sets \u{00d7} \(day.repRange) reps \u{00b7} \(day.restSeconds)s rest")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(day.exerciseIds, id: \.self) { id in
                if let exercise = ExerciseLibrary.byId(id) {
                    NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                        HStack {
                            Image(systemName: exercise.equipment.systemImage)
                                .foregroundStyle(exercise.primaryMuscles.first?.color ?? .secondary)
                            Text(exercise.name).font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
