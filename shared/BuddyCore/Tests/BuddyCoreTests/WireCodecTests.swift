import XCTest
@testable import BuddyCore

final class WireCodecTests: XCTestCase {

    private struct Probe: Codable, Equatable {
        let a: Int
        let b: String
    }

    func testRoundTrip() throws {
        let session = UUID()
        let from = UUID()
        let payload = Probe(a: 42, b: "hello")
        let encoded = try WireCodec.encode(
            payload, kind: .input,
            sessionId: session, from: from, timestamp: 1735689600000
        )
        let (frame, decoded) = try WireCodec.decode(encoded, as: Probe.self)
        XCTAssertEqual(frame.v, WireFrame.currentVersion)
        XCTAssertEqual(frame.sessionId, session)
        XCTAssertEqual(frame.from, from)
        XCTAssertEqual(frame.kind, .input)
        XCTAssertEqual(frame.ts, 1735689600000)
        XCTAssertEqual(decoded, payload)
    }

    func testRejectsUnknownVersion() throws {
        // Hand-craft a v=999 frame.
        let envelope: [String: Any] = [
            "v": 999,
            "sessionId": UUID().uuidString,
            "from": UUID().uuidString,
            "kind": "input",
            "ts": 0,
            "payload": Data().base64EncodedString()
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope, options: [])
        XCTAssertThrowsError(try WireCodec.decode(data, as: WireCodecTests.Probe.self)) { error in
            guard case WireCodec.Error.unsupportedVersion(let v) = error else {
                XCTFail("expected .unsupportedVersion, got \(error)")
                return
            }
            XCTAssertEqual(v, 999)
        }
    }

    func testFrameUnframeRoundTripsLengthPrefixed() {
        let payload = Data([1,2,3,4,5,6,7])
        let framed = WireCodec.frame(payload)
        XCTAssertEqual(framed.count, 4 + payload.count)
        guard let (out, consumed) = WireCodec.unframe(framed) else {
            XCTFail("unframe returned nil")
            return
        }
        XCTAssertEqual(out, payload)
        XCTAssertEqual(consumed, framed.count)
    }

    func testUnframeReturnsNilOnPartialBuffer() {
        let payload = Data([1,2,3,4,5,6,7])
        let framed = WireCodec.frame(payload)
        XCTAssertNil(WireCodec.unframe(framed.prefix(3)))   // not enough for length
        XCTAssertNil(WireCodec.unframe(framed.prefix(framed.count - 1))) // missing last byte
    }
}
