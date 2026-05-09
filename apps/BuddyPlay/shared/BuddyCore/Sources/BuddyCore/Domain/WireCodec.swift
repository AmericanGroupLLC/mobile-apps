import Foundation

/// Pure encode/decode for the BuddyPlay wire format. JSON in v1; CBOR opt-in
/// via flag in v1.1.
public enum WireCodec {

    public enum Error: Swift.Error, Equatable {
        case unsupportedVersion(Int)
        case malformed(String)
    }

    /// Encode a `Codable` payload into a length-prefixed `WireFrame` blob
    /// suitable for the on-the-wire framing.
    public static func encode<P: Codable>(
        _ payload: P,
        kind: WireFrame.Kind,
        sessionId: UUID,
        from: UUID,
        timestamp: Int64
    ) throws -> Data {
        let payloadData = try jsonEncoder().encode(payload)
        let frame = WireFrame(
            sessionId: sessionId,
            from: from,
            kind: kind,
            ts: timestamp,
            payload: payloadData
        )
        return try jsonEncoder().encode(frame)
    }

    /// Decode the envelope, surface schema mismatches as `.unsupportedVersion`,
    /// then decode the payload into the requested `Codable` type.
    public static func decode<P: Codable>(
        _ data: Data,
        as: P.Type
    ) throws -> (frame: WireFrame, payload: P) {
        let frame: WireFrame
        do {
            frame = try jsonDecoder().decode(WireFrame.self, from: data)
        } catch {
            throw Error.malformed("envelope decode failed: \(error)")
        }
        guard frame.v == WireFrame.currentVersion else {
            throw Error.unsupportedVersion(frame.v)
        }
        do {
            let payload = try jsonDecoder().decode(P.self, from: frame.payload)
            return (frame, payload)
        } catch {
            throw Error.malformed("payload decode failed: \(error)")
        }
    }

    /// Length-prefixed framing used by `WifiTransport`. 4-byte big-endian
    /// length followed by `bytes`.
    public static func frame(_ bytes: Data) -> Data {
        var out = Data(capacity: 4 + bytes.count)
        var len = UInt32(bytes.count).bigEndian
        withUnsafeBytes(of: &len) { out.append(contentsOf: $0) }
        out.append(bytes)
        return out
    }

    /// Inverse of `frame`. Returns `nil` if the buffer doesn't yet hold a
    /// complete frame; the consumer should accumulate more bytes and try
    /// again. Returns the parsed payload + the number of bytes consumed.
    public static func unframe(_ buffer: Data) -> (payload: Data, consumed: Int)? {
        guard buffer.count >= 4 else { return nil }
        let len = buffer.withUnsafeBytes { raw -> UInt32 in
            raw.load(fromByteOffset: 0, as: UInt32.self).bigEndian
        }
        let total = 4 + Int(len)
        guard buffer.count >= total else { return nil }
        let payload = buffer.subdata(in: 4..<total)
        return (payload, total)
    }

    // MARK: - JSON config

    private static func jsonEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }
    private static func jsonDecoder() -> JSONDecoder {
        JSONDecoder()
    }
}
