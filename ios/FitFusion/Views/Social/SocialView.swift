import SwiftUI
import FitFusionCore

/// Layer 5 social hub: friends list, active challenges, leaderboard, badges
/// grid, streaks ribbon. Pulls from `FriendsStore`, `ChallengesStore`,
/// `LeaderboardClient`, plus Core Data badge / streak entities.
struct SocialView: View {
    @ObservedObject private var friends = FriendsStore.shared
    @ObservedObject private var challenges = ChallengesStore.shared

    @State private var leaderboard: [LeaderboardClient.Entry] = []
    @State private var newFriendName = ""
    @State private var newFriendHandle = ""
    @State private var showAddFriend = false
    @State private var showCreateChallenge = false
    @State private var newChallengeTitle = ""
    @State private var newChallengeKind = "steps"
    @State private var newChallengeDays = 7
    @State private var newChallengeTarget = 70_000.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    streaksRibbon
                    challengesSection
                    leaderboardSection
                    badgesSection
                    friendsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Friend") { showAddFriend = true }
                        Button("Create Challenge") { showCreateChallenge = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) { addFriendSheet }
            .sheet(isPresented: $showCreateChallenge) { createChallengeSheet }
            .task {
                friends.reload()
                challenges.reload()
                if let first = challenges.active.first {
                    leaderboard = (try? await LeaderboardClient.shared.entries(for: 1)) ?? []
                    _ = first
                }
            }
        }
    }

    // MARK: - Streaks ribbon

    private var streaksRibbon: some View {
        let raw = CloudStore.shared.fetchStreaks()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if raw.isEmpty {
                    streakChip(kind: "Workout", current: 0, longest: 0)
                } else {
                    ForEach(raw, id: \.objectID) { obj in
                        streakChip(
                            kind: (obj.value(forKey: "kind") as? String) ?? "Streak",
                            current: Int((obj.value(forKey: "currentDays") as? Int32) ?? 0),
                            longest: Int((obj.value(forKey: "longestDays") as? Int32) ?? 0)
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func streakChip(kind: String, current: Int, longest: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text(kind).font(.caption.bold())
            }
            Text("\(current) day\(current == 1 ? "" : "s")")
                .font(.title3.bold())
            Text("Best: \(longest)").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Challenges

    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Challenges").font(.headline)
            if challenges.active.isEmpty {
                Button { showCreateChallenge = true } label: {
                    Label("Create your first challenge", systemImage: "plus")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(challenges.active) { c in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(c.title).font(.subheadline.bold())
                            Text("\(c.kind.capitalized) \u{00b7} target \(Int(c.target))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(c.endsAt, style: .relative)
                            .font(.caption2).foregroundStyle(.indigo)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Leaderboard").font(.headline)
            if leaderboard.isEmpty {
                Text("Join a challenge to see standings.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(leaderboard) { entry in
                    HStack {
                        Text(entry.rankBadge).font(.title2)
                        VStack(alignment: .leading) {
                            Text(entry.name).font(.subheadline.bold())
                            Text(entry.email).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(entry.score))").font(.title3.bold())
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    // MARK: - Badges

    private var badgesSection: some View {
        let badges = CloudStore.shared.fetchBadges()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Badges").font(.headline)
            if badges.isEmpty {
                Text("Earn your first badge by logging a workout this week.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                    ForEach(badges, id: \.objectID) { b in
                        VStack(spacing: 4) {
                            Image(systemName: "rosette").font(.title)
                                .foregroundStyle(.yellow)
                            Text((b.value(forKey: "title") as? String) ?? "Badge")
                                .font(.caption2.bold()).multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Friends

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friends").font(.headline)
            if friends.friends.isEmpty {
                Button { showAddFriend = true } label: {
                    Label("Add a friend", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity).padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(friends.friends) { f in
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2).foregroundStyle(.indigo)
                        VStack(alignment: .leading) {
                            Text(f.name).font(.subheadline.bold())
                            Text("@\(f.handle)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Sheets

    private var addFriendSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newFriendName)
                TextField("Handle", text: $newFriendHandle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddFriend = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            _ = await friends.addFriend(name: newFriendName, handle: newFriendHandle)
                            newFriendName = ""; newFriendHandle = ""
                            showAddFriend = false
                        }
                    }
                    .disabled(newFriendName.isEmpty || newFriendHandle.isEmpty)
                }
            }
        }
    }

    private var createChallengeSheet: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $newChallengeTitle)
                Picker("Kind", selection: $newChallengeKind) {
                    Text("Steps").tag("steps")
                    Text("Active Minutes").tag("active_minutes")
                    Text("Workouts").tag("workouts")
                }
                Stepper("Days: \(newChallengeDays)", value: $newChallengeDays, in: 1...30)
                HStack {
                    Text("Target")
                    Spacer()
                    TextField("0", value: $newChallengeTarget, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCreateChallenge = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            _ = await challenges.join(
                                title: newChallengeTitle,
                                kind: newChallengeKind,
                                days: newChallengeDays,
                                target: newChallengeTarget
                            )
                            newChallengeTitle = ""
                            showCreateChallenge = false
                        }
                    }
                    .disabled(newChallengeTitle.isEmpty)
                }
            }
        }
    }
}
