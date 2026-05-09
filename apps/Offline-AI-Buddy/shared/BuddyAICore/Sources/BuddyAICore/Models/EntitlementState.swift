import Foundation

/// The flattened entitlement state read by gating UI everywhere in the
/// app. RevenueCat (or `NoopEntitlementService`) is the source of truth.
public struct EntitlementState: Codable, Hashable, Sendable {
    public var proUnlocked: Bool
    public var source: Source
    public var expiresAt: Date?

    public init(proUnlocked: Bool, source: Source, expiresAt: Date? = nil) {
        self.proUnlocked = proUnlocked
        self.source = source
        self.expiresAt = expiresAt
    }

    public static let free: EntitlementState = .init(proUnlocked: false, source: .free)

    public enum Source: String, Codable, Sendable {
        case free
        case subscription
        case lifetime
    }
}
