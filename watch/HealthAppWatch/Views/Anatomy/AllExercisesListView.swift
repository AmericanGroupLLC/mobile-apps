import SwiftUI
import FitFusionCore

/// Browse-all fallback for the Watch when the user knows the exercise name and
/// doesn't want to drill in by anatomy. Simple alphabetical list.
struct AllExercisesListView: View {
    private let exercises: [Exercise] = ExerciseLibrary.exercises
        .sorted { $0.name < $1.name }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(exercises) { ex in
                    NavigationLink {
                        WatchExerciseDetailView(exercise: ex)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: ex.equipment.systemImage)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(.white.opacity(0.18), in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ex.name).font(.caption.weight(.semibold))
                                    .foregroundStyle(.white).lineLimit(2)
                                Text(ex.primaryMuscles.first?.label ?? "")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .navigationTitle("All Exercises")
        .containerBackground(LinearGradient(colors: [.indigo, .purple],
                                            startPoint: .topLeading, endPoint: .bottomTrailing),
                             for: .navigation)
    }
}
