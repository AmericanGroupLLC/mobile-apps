import Foundation

/// The on-the-wire envelope for every BuddyPlay frame. The `v` field is
/// the ONLY breaking-change escape hatch: a decoder receiving an unknown
/// major version returns `.unsupportedVersion` and the UI surfaces an
/// "Update your friend's app" toast.
public struct WireFrame: Codable, Hashable, Sendable {
    public static let currentVersion: Int = 1

    public let v: Int
    public let sessionId: UUID
    public let from: UUID
    public let kind: Kind
    public let ts: Int64
    /// Raw JSON payload. Kept opaque at the envelope level so per-game
    /// decoders can decode it into their own input/state types.
    public let payload: Data

    public init(
        v: Int = WireFrame.currentVersion,
        sessionId: UUID,
        from: UUID,
        kind: Kind,
        ts: Int64,
        payload: Data
    ) {
        self.v = v
        self.sessionId = sessionId
        self.from = from
        self.kind = kind
        self.ts = ts
        self.payload = payload
    }

    public enum Kind: String, Codable, Sendable {
        case input
        case state
        case lobby
        case ping
        case pong
    }

    private enum CodingKeys: String, CodingKey {
        case v, sessionId, from, kind, ts, payload
    }

    // Encode payload as base64 when serialised as JSON so it survives the
    // round-trip. Binary transports (CBOR — v1.1) can swap this out for raw.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        v = try c.decode(Int.self, forKey: .v)
        sessionId = try c.decode(UUID.self, forKey: .sessionId)
        from = try c.decode(UUID.self, forKey: .from)
        kind = try c.decode(Kind.self, forKey: .kind)
        ts = try c.decode(Int64.self, forKey: .ts)
        let b64 = try c.decode(String.self, forKey: .payload)
        guard let data = Data(base64Encoded: b64) else {
            throw DecodingError.dataCorruptedError(
                forKey: .payload, in: c,
                debugDescription: "payload is not valid base64"
            )
        }
        payload = data
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(v, forKey: .v)
        try c.encode(sessionId, forKey: .sessionId)
        try c.encode(from, forKey: .from)
        try c.encode(kind, forKey: .kind)
        try c.encode(ts, forKey: .ts)
        try c.encode(payload.base64EncodedString(), forKey: .payload)
    }
}
