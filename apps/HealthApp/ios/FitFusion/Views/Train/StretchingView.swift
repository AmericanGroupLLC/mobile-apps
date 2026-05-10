import SwiftUI
import FitFusionCore

/// Stretches & mobility library \u{2014} same row UI as the lift library, but
/// pre-filtered to `isStretch == true` and excluding the workout logger
/// (since stretches are timed, not rep-based).
struct StretchingView: View {
    private var stretches: [Exercise] {
        ExerciseLibrary.exercises.filter { $0.isStretch }
    }

    var body: some View {
        List(stretches) { ex in
            NavigationLink { ExerciseDetailView(exercise: ex) } label: {
                ExerciseRow(exercise: ex)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("Stretching")
    }
}
