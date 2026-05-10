import SwiftUI
import DriftCore

struct MatchesScreen: View {
    @State private var matches: [Wave] = []

    var body: some View {
        NavigationStack {
            List(matches, id: \.id) { w in
                HStack {
                    Image(systemName: "heart.fill").foregroundStyle(.pink)
                    VStack(alignment: .leading) {
                        Text("Matched in \(w.layer.rawValue.capitalized)")
                        Text(w.matchedAt?.formatted() ?? "—").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Matches")
            .overlay {
                if matches.isEmpty {
                    ContentUnavailableView("No matches yet",
                        systemImage: "hand.wave",
                        description: Text("Wave at someone in Discover to start."))
                }
            }
        }
    }
}
