import Foundation

public struct Wave: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let fromProfileId: UUID
    public let toProfileId: UUID
    public let layer: Layer
    public var status: WaveStatus
    public let createdAt: Date
    public var matchedAt: Date?

    public init(
        id: UUID = UUID(),
        fromProfileId: UUID,
        toProfileId: UUID,
        layer: Layer,
        status: WaveStatus = .pending,
        createdAt: Date = Date(),
        matchedAt: Date? = nil
    ) {
        self.id = id
        self.fromProfileId = fromProfileId
        self.toProfileId = toProfileId
        self.layer = layer
        self.status = status
        self.createdAt = createdAt
        self.matchedAt = matchedAt
    }
}
