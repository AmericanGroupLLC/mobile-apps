import SwiftUI
import BuddyCore

/// Local rivalries screen. Replaces a cloud leaderboard.
struct RivalriesScreen: View {
    @EnvironmentObject private var rivalries: RivalriesModel

    var body: some View {
        NavigationStack {
            Group {
                if rivalries.rivalries.isEmpty {
                    emptyState
                } else {
                    List(rivalries.rivalries, id: \.opponentId) { rivalry in
                        RivalryRow(rivalry: rivalry)
                    }
                }
            }
            .navigationTitle("Rivalries")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No matches yet")
                .font(.headline)
            Text("Play someone and your head-to-head record will show up here. We never send this anywhere.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .padding(.top, 60)
    }
}

private struct RivalryRow: View {
    let rivalry: Rivalry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rivalry.opponentName).font(.headline)
            HStack(spacing: 14) {
                ForEach(GameKind.allCases, id: \.self) { kind in
                    if let r = rivalry.perGame[kind], r.totalPlayed > 0 {
                        VStack(alignment: .leading) {
                            Text(kind.displayName)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("\(r.wins)W · \(r.losses)L · \(r.draws)D")
                                .font(.callout)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
