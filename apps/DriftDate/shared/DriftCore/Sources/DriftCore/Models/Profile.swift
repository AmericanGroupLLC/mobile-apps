import Foundation

public struct Photo: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let profileId: UUID
    public let storagePath: String
    public let sortOrder: Int            // 1...6
    public let isVerificationSelfie: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        profileId: UUID,
        storagePath: String,
        sortOrder: Int,
        isVerificationSelfie: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.storagePath = storagePath
        self.sortOrder = sortOrder
        self.isVerificationSelfie = isVerificationSelfie
        self.createdAt = createdAt
    }
}

public struct Prompt: Codable, Equatable, Sendable {
    public let slot: Int                 // 1...3
    public let key: String               // e.g. "looking_for"
    public let response: String

    public init(slot: Int, key: String, response: String) {
        self.slot = slot
        self.key = key
        self.response = response
    }
}

/// One Drift profile. Mirrors the `public.profiles` Postgres row + joined photos/prompts.
public struct Profile: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public var photos: [Photo]
    public var voicePromptUrl: URL?
    public var intent: Intent
    public var vibeTags: [String]
    public var prompts: [Prompt]
    public var verifiedAt: Date?
    public var ageRange: ClosedRange<Int>
    public var zipPrefix3: String?
    public var countyFips: String?
    public var stateCode: String?
    public var discoverableLayers: Set<Layer>
    public var lastActiveAt: Date
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        displayName: String,
        photos: [Photo] = [],
        voicePromptUrl: URL? = nil,
        intent: Intent,
        vibeTags: [String] = [],
        prompts: [Prompt] = [],
        verifiedAt: Date? = nil,
        ageRange: ClosedRange<Int> = 18...99,
        zipPrefix3: String? = nil,
        countyFips: String? = nil,
        stateCode: String? = nil,
        discoverableLayers: Set<Layer> = Set(Layer.allCases),
        lastActiveAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.photos = photos
        self.voicePromptUrl = voicePromptUrl
        self.intent = intent
        self.vibeTags = vibeTags
        self.prompts = prompts
        self.verifiedAt = verifiedAt
        self.ageRange = ageRange
        self.zipPrefix3 = zipPrefix3
        self.countyFips = countyFips
        self.stateCode = stateCode
        self.discoverableLayers = discoverableLayers
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
    }

    public var isVerified: Bool { verifiedAt != nil }
}
