import Foundation

/// A thin URLSession-based wrapper around the bits of the Supabase REST
/// API that Drift uses. We deliberately avoid `supabase-swift` to keep
/// the surface tiny and easy to mock in tests.
///
/// Reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `Bundle.main.infoDictionary`
/// (set via `Info.plist` build settings) so the same binary points at
/// dev / staging / prod via a build-time substitution.
public final class SupabaseClient {
    public let baseURL: URL
    public let anonKey: String
    private let session: URLSession
    private var jwt: String?

    public init(baseURL: URL, anonKey: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.session = session
    }

    public static func fromBundle(bundle: Bundle = .main, session: URLSession = .shared) -> SupabaseClient? {
        let url = (bundle.infoDictionary?["SUPABASE_URL"] as? String).flatMap(URL.init(string:))
        let key =  bundle.infoDictionary?["SUPABASE_ANON_KEY"] as? String
        guard let url, let key, !key.isEmpty else { return nil }
        return SupabaseClient(baseURL: url, anonKey: key, session: session)
    }

    public func setJWT(_ token: String?) {
        self.jwt = token
    }

    // MARK: - REST

    public func get<T: Decodable>(
        _ path: String,
        query: [String: String] = [:],
        as type: T.Type = T.self
    ) async throws -> T {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: comps.url!)
        applyHeaders(&req)
        return try await execute(req)
    }

    public func post<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        as type: T.Type = T.self
    ) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        applyHeaders(&req)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.driftDefault.encode(body)
        return try await execute(req)
    }

    public func invokeFunction<Body: Encodable, T: Decodable>(
        _ name: String,
        body: Body,
        as type: T.Type = T.self
    ) async throws -> T {
        try await post("functions/v1/\(name)", body: body, as: T.self)
    }

    // MARK: - Internals

    private func applyHeaders(_ req: inout URLRequest) {
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let jwt {
            req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        } else {
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func execute<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SupabaseError.http(status: http.statusCode, body: data)
        }
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try JSONDecoder.driftDefault.decode(T.self, from: data)
    }
}

public struct EmptyResponse: Decodable {}

public enum SupabaseError: Error, Equatable {
    case http(status: Int, body: Data)
}

extension JSONEncoder {
    public static let driftDefault: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    public static let driftDefault: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
