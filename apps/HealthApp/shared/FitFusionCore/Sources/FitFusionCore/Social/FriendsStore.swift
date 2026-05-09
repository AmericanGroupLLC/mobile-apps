import Foundation
import CoreData
import Combine

/// Layer 5 friends list. Local source of truth lives in the CloudKit-synced
/// `FriendEntity`. Adds + deletes also fan out to the Express backend so the
/// Android / web mobile client can see them.
@MainActor
public final class FriendsStore: ObservableObject {

    public static let shared = FriendsStore()
    private init() { reload() }

    @Published public private(set) var friends: [Friend] = []

    public struct Friend: Identifiable, Hashable, Codable {
        public let id: UUID
        public let name: String
        public let handle: String
        public let recordID: String?
        public let addedAt: Date

        public init(id: UUID, name: String, handle: String,
                    recordID: String? = nil, addedAt: Date = Date()) {
            self.id = id
            self.name = name
            self.handle = handle
            self.recordID = recordID
            self.addedAt = addedAt
        }
    }

    public func reload() {
        let raw = CloudStore.shared.fetchFriends()
        self.friends = raw.compactMap { Self.mapFriend($0) }
    }

    @discardableResult
    public func addFriend(name: String, handle: String, recordID: String? = nil) async -> Friend? {
        // 1) Local CloudKit-synced entity.
        guard let entity = CloudStore.shared.addFriend(name: name, handle: handle, recordID: recordID),
              let mapped = Self.mapFriend(entity) else {
            return nil
        }
        // 2) Best-effort backend mirror for cross-platform clients.
        struct Body: Encodable { let name: String; let handle: String; let record_id: String? }
        _ = try? await APIClient.shared.sendRequest(
            path: "/api/social/friend",
            method: "POST",
            body: Body(name: name, handle: handle, record_id: recordID),
            as: NoOpResponse.self
        )
        reload()
        return mapped
    }

    private static func mapFriend(_ obj: NSManagedObject) -> Friend? {
        guard let id = obj.value(forKey: "id") as? UUID,
              let name = obj.value(forKey: "name") as? String,
              let handle = obj.value(forKey: "handle") as? String else { return nil }
        return Friend(
            id: id,
            name: name,
            handle: handle,
            recordID: obj.value(forKey: "recordID") as? String,
            addedAt: (obj.value(forKey: "addedAt") as? Date) ?? Date()
        )
    }
}

struct NoOpResponse: Decodable {}
