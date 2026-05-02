import SwiftUI
import FitFusionCore

/// Train tab hub. Surfaces all training entry points: pre-built MyHealth
/// templates, MuscleWiki-style anatomy picker, exercise library, programs,
/// stretching, and a custom workout builder.
struct TrainView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 12) {
                    tile(title: "Anatomy",
                         subtitle: "Tap a muscle",
                         system: "figure.arms.open",
                         colors: [.red, .pink]) {
                        AnatomyPickerView()
                    }
                    tile(title: "Library",
                         subtitle: "All exercises",
                         system: "books.vertical.fill",
                         colors: [.indigo, .purple]) {
                        ExerciseLibraryView()
                    }
                    tile(title: "Programs",
                         subtitle: "PPL \u{00b7} UL \u{00b7} Full Body",
                         system: "calendar",
                         colors: [.blue, .cyan]) {
                        ProgramsView()
                    }
                    tile(title: "Stretching",
                         subtitle: "Mobility + flexibility",
                         system: "figure.cooldown",
                         colors: [.teal, .green]) {
                        StretchingView()
                    }
                    tile(title: "Custom",
                         subtitle: "Build your own",
                         system: "square.stack.3d.up.fill",
                         colors: [.orange, .pink]) {
                        CustomWorkoutBuilderView()
                    }
                    tile(title: "Send to Watch",
                         subtitle: "Apple-native templates",
                         system: "applewatch",
                         colors: [.gray, .indigo]) {
                        WorkoutLibraryView()
                    }
                }
                .padding()
            }
            .navigationTitle("Train")
        }
    }

    @ViewBuilder
    private func tile<Destination: View>(title: String,
                                         subtitle: String,
                                         system: String,
                                         colors: [Color],
                                         @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: system)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.white.opacity(0.18), in: Circle())
                Spacer()
                Text(title).font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.caption2).foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .padding()
            .background(LinearGradient(colors: colors,
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
