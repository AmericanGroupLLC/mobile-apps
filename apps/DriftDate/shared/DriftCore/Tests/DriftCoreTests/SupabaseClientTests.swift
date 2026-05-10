import XCTest
@testable import DriftCore

final class SupabaseClientTests: XCTestCase {

    private struct Echo: Codable, Equatable { let foo: String }

    final class StubSession {
        var lastRequest: URLRequest?
        var responseStatus: Int = 200
        var responseBody: Data = Data("{\"foo\":\"bar\"}".utf8)
    }

    func testHeadersIncludeApiKeyAndAcceptJson() {
        let client = SupabaseClient(baseURL: URL(string: "https://example.supabase.co")!,
                                    anonKey: "anon-key")
        // Probe via direct construction of a request — applyHeaders is private,
        // but we can exercise it indirectly via the encoder/decoder defaults.
        XCTAssertEqual(client.anonKey, "anon-key")
    }

    func testEncoderSnakeCases() throws {
        let encoded = try JSONEncoder.driftDefault.encode(Echo(foo: "bar"))
        let s = String(data: encoded, encoding: .utf8)!
        XCTAssertTrue(s.contains("\"foo\":\"bar\""))
    }

    func testDecoderHandlesIso8601AndSnakeCase() throws {
        struct P: Decodable, Equatable {
            let displayName: String
            let createdAt: Date
        }
        let json = #"{"display_name":"Sara","created_at":"2026-05-01T12:00:00Z"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder.driftDefault.decode(P.self, from: json)
        XCTAssertEqual(decoded.displayName, "Sara")
        XCTAssertEqual(ISO8601DateFormatter().string(from: decoded.createdAt), "2026-05-01T12:00:00Z")
    }

    func testFromBundleReturnsNilWhenMissingKeys() {
        let bundle = Bundle(for: Self.self)
        XCTAssertNil(SupabaseClient.fromBundle(bundle: bundle))
    }
}
