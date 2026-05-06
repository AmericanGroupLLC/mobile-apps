import SwiftUI
import BuddyCore

/// Home tab. Horizontal "card scroller" of the 3 games (Netflix/Switch-style),
/// DuoPlay/Party tabs, persistent floating "Join Nearby Game" button.
struct HomeScreen: View {
    @State private var lobbyTab: LobbyTab = .duoplay
    @State private var hostKind: GameKind?
    @State private var showJoinSheet = false

    enum LobbyTab: String, CaseIterable, Hashable {
        case all      = "All games"
        case duoplay  = "DuoPlay (2P)"
        case party    = "Party (3-4P)"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Picker("", selection: $lobbyTab) {
                            ForEach(LobbyTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(false)

                        if lobbyTab == .party {
                            partyDimmedCard
                        } else {
                            cardScroller
                            lastPlayedSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
                joinNearbyFAB
            }
            .navigationTitle("BuddyPlay")
            .sheet(item: $hostKind) { kind in
                HostLobbyScreen(kind: kind)
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinLobbyScreen()
            }
        }
    }

    private var cardScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(GameKind.allCases, id: \.self) { kind in
                    GameCard(kind: kind)
                        .onTapGesture { hostKind = kind }
                }
            }
        }
    }

    private var lastPlayedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last played")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("No games yet — host one above or join a nearby friend.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    private var partyDimmedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Party mode (3-4 players)")
                .font(.headline)
            Text("Coming in v1.1.")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var joinNearbyFAB: some View {
        Button {
            showJoinSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Join Nearby Game")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Color.accentColor)
            .clipShape(Capsule())
            .shadow(radius: 6)
        }
        .padding(.bottom, 16)
    }
}

private struct GameCard: View {
    let kind: GameKind

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
                .frame(width: 60, height: 60)
            Text(kind.displayName)
                .font(.title3.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(transports, id: \.self) { t in
                    Text(t)
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .frame(width: 220, height: 220)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var iconName: String {
        switch kind {
        case .chess: return "crown.fill"
        case .ludo:  return "die.face.5.fill"
        case .racer: return "car.fill"
        }
    }
    private var subtitle: String {
        switch kind {
        case .chess: return "Turn-based · classic 8×8"
        case .ludo:  return "Turn-based · DuoPlay"
        case .racer: return "Real-time · Wi-Fi only"
        }
    }
    private var transports: [String] {
        kind.supportsBle ? ["Wi-Fi", "Hotspot", "BLE"] : ["Wi-Fi", "Hotspot"]
    }
}

extension GameKind: Identifiable {
    public var id: String { rawValue }
}
