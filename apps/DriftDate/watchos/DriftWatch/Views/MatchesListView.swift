import SwiftUI
import DriftCore

struct MatchesListView: View {
    @State private var matches: [Wave] = []

    var body: some View {
        NavigationStack {
            List(matches, id: \.id) { wave in
                NavigationLink(value: wave) {
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.pink)
                        Text(wave.layer.rawValue.capitalized)
                    }
                }
            }
            .navigationDestination(for: Wave.self) { QuickReplyView(wave: $0) }
            .navigationTitle("Drift")
            .overlay {
                if matches.isEmpty {
                    Text("No matches yet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
