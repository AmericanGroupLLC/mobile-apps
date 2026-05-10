import Foundation

public enum APIConfig {
    /// Default to localhost for Simulator with backend on same Mac.
    /// Real device: set via Settings (apiBaseURL UserDefaults key).
    public static var baseURL: String {
        if let stored = UserDefaults.standard.string(forKey: "apiBaseURL"), !stored.isEmpty {
            return stored
        }
        return "http://localhost:4000"
    }
}

public final class APIClient {
    public static let shared = APIClient()
    private init() {
        // Restore guest flag at boot so background tasks short-circuit correctly.
        self.isGuest = UserDefaults.standard.bool(forKey: "isGuest")
    }

    private var token: String? {
        get { UserDefaults.standard.string(forKey: "token") }
        set { UserDefaults.standard.set(newValue, forKey: "token") }
    }

    /// When true, every authenticated route short-circuits and returns a local
    /// stub. Public-API routes (no `auth: true`) still go to the network so
    /// guest users can still query MyHealthfinder, Open Food Facts, OpenFDA, etc.
    public private(set) var isGuest: Bool = false

    public func setToken(_ t: String?) { token = t }
    public var currentToken: String? { token }

    public func setGuest(_ flag: Bool) {
        self.isGuest = flag
        if flag { token = nil }
    }

    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        auth: Bool = true
    ) throws -> URLRequest {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            throw APIError(error: "Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let t = token {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        return req
    }

    public func send<T: Decodable>(_ req: URLRequest, as type: T.Type) async throws -> T {
        // Guest short-circuit: any request that requires auth resolves to an
        // in-memory empty / OK response so the existing UI keeps compiling.
        if isGuest, req.value(forHTTPHeaderField: "Authorization") == nil,
           req.url?.path.hasPrefix("/api/") == true {
            // Allow truly public routes through. Auth-required routes will not
            // have an Authorization header set in guest mode — short-circuit.
            if let stub = Self.guestStub(for: T.self) { return stub }
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(error: "Bad response")
        }
        if !(200..<300).contains(http.statusCode) {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(error: "HTTP \(http.statusCode)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Generic public helper for ad-hoc endpoints (used by Social stores).
    /// Empty-204 responses can be decoded as `EmptyResponse`.
    public func sendRequest<Body: Encodable, T: Decodable>(
        path: String,
        method: String = "POST",
        body: Body? = nil,
        as type: T.Type
    ) async throws -> T {
        let req = try makeRequest(path: path, method: method, body: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(error: "Bad response")
        }
        if !(200..<300).contains(http.statusCode) {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(error: "HTTP \(http.statusCode)")
        }
        if data.isEmpty, let empty = EmptyResponse() as? T { return empty }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Convenience for GET requests with no body.
    public func sendRequest<T: Decodable>(path: String, as type: T.Type) async throws -> T {
        try await sendRequest(path: path, method: "GET", body: Optional<EmptyBody>.none, as: type)
    }

    // MARK: - Auth
    struct LoginBody: Encodable { let email: String; let password: String }
    struct RegisterBody: Encodable { let name: String; let email: String; let password: String }

    public func login(email: String, password: String) async throws -> AuthResponse {
        let req = try makeRequest(path: "/api/auth/login",
                                  method: "POST",
                                  body: LoginBody(email: email, password: password),
                                  auth: false)
        let resp: AuthResponse = try await send(req, as: AuthResponse.self)
        token = resp.token
        return resp
    }

    public func register(name: String, email: String, password: String) async throws -> AuthResponse {
        let req = try makeRequest(path: "/api/auth/register",
                                  method: "POST",
                                  body: RegisterBody(name: name, email: email, password: password),
                                  auth: false)
        let resp: AuthResponse = try await send(req, as: AuthResponse.self)
        token = resp.token
        return resp
    }

    // MARK: - Profile
    public func getProfile() async throws -> ProfileResponse {
        let req = try makeRequest(path: "/api/profile")
        return try await send(req, as: ProfileResponse.self)
    }

    // MARK: - Metrics
    struct MetricBody: Encodable { let type: String; let value: Double; let unit: String? }

    @discardableResult
    public func logMetric(type: String, value: Double, unit: String? = nil) async throws -> Metric {
        let req = try makeRequest(path: "/api/profile/metrics",
                                  method: "POST",
                                  body: MetricBody(type: type, value: value, unit: unit))
        let resp: MetricResponse = try await send(req, as: MetricResponse.self)
        return resp.metric
    }

    public func listMetrics(type: String? = nil, limit: Int = 20) async throws -> [Metric] {
        var path = "/api/profile/metrics?limit=\(limit)"
        if let type = type { path += "&type=\(type)" }
        let req = try makeRequest(path: path)
        let resp: MetricListResponse = try await send(req, as: MetricListResponse.self)
        return resp.metrics
    }

    // MARK: - Nutrition
    struct MealBody: Encodable {
        let name: String
        let kcal: Double
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
        let barcode: String?
    }

    @discardableResult
    public func logMeal(name: String, kcal: Double, protein: Double,
                        carbs: Double, fat: Double, barcode: String? = nil) async throws -> Meal {
        let req = try makeRequest(path: "/api/nutrition/meal",
                                  method: "POST",
                                  body: MealBody(name: name, kcal: kcal,
                                                 protein_g: protein, carbs_g: carbs,
                                                 fat_g: fat, barcode: barcode))
        let resp: MealResponse = try await send(req, as: MealResponse.self)
        return resp.meal
    }

    public func todayMeals() async throws -> MealListResponse {
        let req = try makeRequest(path: "/api/nutrition/today")
        return try await send(req, as: MealListResponse.self)
    }

    // MARK: - Insights
    public func readiness() async throws -> ReadinessResponse {
        let req = try makeRequest(path: "/api/insights/readiness")
        return try await send(req, as: ReadinessResponse.self)
    }

    public func weeklyInsights() async throws -> WeeklyResponse {
        let req = try makeRequest(path: "/api/insights/weekly")
        return try await send(req, as: WeeklyResponse.self)
    }
}

// Helper to encode heterogeneous Encodable bodies
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ wrapped: T) { _encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

/// Empty body sentinel for GET requests through `APIClient.sendRequest(...)`.
public struct EmptyBody: Encodable {
    public init() {}
}

/// Decodable for endpoints that return 204 / empty body.
public struct EmptyResponse: Decodable {
    public init() {}
}

// MARK: - Guest mode stubs

extension APIClient {
    /// Best-effort empty / sensible defaults for guest-mode short-circuiting.
    /// Keeps existing call-sites compiling without breaking the UI.
    static func guestStub<T>(for type: T.Type) -> T? {
        if T.self == EmptyResponse.self { return EmptyResponse() as? T }
        if T.self == AuthResponse.self {
            let user = User(id: 0, email: "guest@local", name: "Guest")
            return AuthResponse(user: user, token: "guest") as? T
        }
        if T.self == ProfileResponse.self {
            let user = User(id: 0, email: "guest@local", name: "Guest")
            return ProfileResponse(user: user, profile: Profile(), bmi: nil) as? T
        }
        if T.self == MetricResponse.self {
            return MetricResponse(metric: Metric(id: 0, user_id: 0, type: "", value: 0,
                                                 unit: nil,
                                                 recorded_at: ISO8601DateFormatter().string(from: Date()))) as? T
        }
        if T.self == MetricListResponse.self { return MetricListResponse(metrics: []) as? T }
        if T.self == MealResponse.self {
            return MealResponse(meal: Meal(id: 0, user_id: 0, name: "", kcal: 0,
                                           protein_g: 0, carbs_g: 0, fat_g: 0,
                                           barcode: nil,
                                           recorded_at: ISO8601DateFormatter().string(from: Date()))) as? T
        }
        if T.self == MealListResponse.self {
            return MealListResponse(meals: [],
                                    totals: MealTotals(kcal: 0, protein_g: 0, carbs_g: 0, fat_g: 0)) as? T
        }
        if T.self == ReadinessResponse.self {
            return ReadinessResponse(score: 70, suggestion: "Stay consistent.",
                                     hrv_avg: nil, sleep_hrs: nil, workout_minutes: nil) as? T
        }
        if T.self == WeeklyResponse.self {
            return WeeklyResponse(aggregates: []) as? T
        }
        return nil
    }
}
