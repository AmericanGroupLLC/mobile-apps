import Foundation
import CoreData
import Combine

/// Layer 5 challenges. Local CloudKit-synced `ChallengeEntity` is mirrored to
/// the Express backend so cross-platform participants can join the same
/// challenge from Android or web.
@MainActor
public final class ChallengesStore: ObservableObject {

    public static let shared = ChallengesStore()
    private init() { reload() }

    @Published public private(set) var active: [Challenge] = []

    public struct Challenge: Identifiable, Hashable, Codable {
        public let id: UUID
        public let title: String
        public let kind: String              // e.g. "steps", "active_minutes", "workouts"
        public let startsAt: Date
        public let endsAt: Date
        public let target: Double
        public let joinedAt: Date

        public init(id: UUID, title: String, kind: String,
                    startsAt: Date, endsAt: Date,
                    target: Double, joinedAt: Date) {
            self.id = id
            self.title = title
            self.kind = kind
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.target = target
            self.joinedAt = joinedAt
        }
    }

    public func reload() {
        let raw = CloudStore.shared.fetchActiveChallenges()
        self.active = raw.compactMap { Self.map($0) }
    }

    @discardableResult
    public func join(title: String, kind: String, days: Int, target: Double) async -> Challenge? {
        let starts = Date()
        let ends = Calendar.current.date(byAdding: .day, value: days, to: starts) ?? starts
        guard let entity = CloudStore.shared.addChallenge(
            title: title, kind: kind,
            startsAt: starts, endsAt: ends, target: target
        ), let mapped = Self.map(entity) else {
            return nil
        }
        struct Body: Encodable {
            let title: String; let kind: String
            let starts_at: String; let ends_at: String; let target: Double
        }
        let iso = ISO8601DateFormatter()
        _ = try? await APIClient.shared.sendRequest(
            path: "/api/social/challenge",
            method: "POST",
            body: Body(title: title, kind: kind,
                       starts_at: iso.string(from: starts),
                       ends_at: iso.string(from: ends),
                       target: target),
            as: NoOpResponse.self
        )
        reload()
        return mapped
    }

    private static func map(_ obj: NSManagedObject) -> Challenge? {
        guard let id = obj.value(forKey: "id") as? UUID,
              let title = obj.value(forKey: "title") as? String,
              let kind = obj.value(forKey: "kind") as? String,
              let starts = obj.value(forKey: "startsAt") as? Date,
              let ends = obj.value(forKey: "endsAt") as? Date else { return nil }
        return Challenge(
            id: id,
            title: title,
            kind: kind,
            startsAt: starts,
            endsAt: ends,
            target: (obj.value(forKey: "target") as? Double) ?? 0,
            joinedAt: (obj.value(forKey: "joinedAt") as? Date) ?? starts
        )
    }
}
