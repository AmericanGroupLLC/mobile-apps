import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// SMART-on-FHIR PKCE OAuth2 client. Generates the authorization URL and
/// exchanges the returned code for tokens. Platform-specific browser
/// launch is delegated to a `FHIROAuthSession` (iOS uses
/// `ASWebAuthenticationSession` — see `Services/FHIROAuthSession.swift`).
///
/// Tokens are stored in the Keychain via `KeychainStore`, scoped per
/// issuer URL so multiple connected health systems are supported (Epic
/// sandbox today, real-world Epic Production / Cerner / etc. later).
public final class FHIROAuthClient {

    public struct Config {
        public let issuer: String
        public let authorizationEndpoint: String
        public let tokenEndpoint: String
        public let clientId: String
        public let redirectURI: String
        public let scopes: [String]
        public init(issuer: String, authorizationEndpoint: String,
                    tokenEndpoint: String, clientId: String,
                    redirectURI: String, scopes: [String]) {
            self.issuer = issuer
            self.authorizationEndpoint = authorizationEndpoint
            self.tokenEndpoint = tokenEndpoint
            self.clientId = clientId
            self.redirectURI = redirectURI
            self.scopes = scopes
        }
    }

    public struct TokenResponse: Decodable {
        public let access_token: String
        public let refresh_token: String?
        public let expires_in: Int?
        public let patient: String?
        public let scope: String?
    }

    public let config: Config

    public init(config: Config) {
        self.config = config
    }

    public static var epicSandbox: FHIROAuthClient {
        FHIROAuthClient(config: Config(
            issuer: EpicSandboxConfig.issuer,
            authorizationEndpoint: EpicSandboxConfig.authorizationEndpoint,
            tokenEndpoint: EpicSandboxConfig.tokenEndpoint,
            clientId: EpicSandboxConfig.clientId,
            redirectURI: EpicSandboxConfig.redirectURI,
            scopes: EpicSandboxConfig.scopes,
        ))
    }

    // MARK: - PKCE helpers

    public static func makeCodeVerifier(length: Int = 64) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        var s = ""
        for _ in 0..<length { s.append(chars.randomElement()!) }
        return s
    }

    public static func codeChallenge(for verifier: String) -> String {
        #if canImport(CryptoKit)
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
        #else
        return verifier // fallback: plain (not recommended)
        #endif
    }

    public static func makeState() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    // MARK: - Authorization URL

    /// Returns the URL to load in the platform browser for the start of
    /// the SMART OAuth dance. The caller stores `verifier` + `state` so
    /// they can be checked on the callback.
    public func authorizationURL(state: String, codeVerifier: String) -> URL? {
        var components = URLComponents(string: config.authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "response_type",          value: "code"),
            URLQueryItem(name: "client_id",              value: config.clientId),
            URLQueryItem(name: "redirect_uri",           value: config.redirectURI),
            URLQueryItem(name: "scope",                  value: config.scopes.joined(separator: " ")),
            URLQueryItem(name: "state",                  value: state),
            URLQueryItem(name: "aud",                    value: config.issuer),
            URLQueryItem(name: "code_challenge",         value: Self.codeChallenge(for: codeVerifier)),
            URLQueryItem(name: "code_challenge_method",  value: "S256"),
        ]
        return components?.url
    }

    // MARK: - Token exchange

    public func exchangeCode(_ code: String, codeVerifier: String) async throws -> TokenResponse {
        guard let url = URL(string: config.tokenEndpoint) else {
            throw NSError(domain: "FHIROAuthClient", code: -1)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": config.redirectURI,
            "client_id": config.clientId,
            "code_verifier": codeVerifier,
        ]
        .map { "\($0.key)=\(percentEncode($0.value))" }
        .joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "FHIROAuthClient",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "FHIR token exchange failed: \(body)"])
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    public func refresh(refreshToken: String) async throws -> TokenResponse {
        guard let url = URL(string: config.tokenEndpoint) else {
            throw NSError(domain: "FHIROAuthClient", code: -1)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": config.clientId,
        ]
        .map { "\($0.key)=\(percentEncode($0.value))" }
        .joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "FHIROAuthClient",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    /// Persist a fresh token into the Keychain. Convenience wrapper.
    public func persist(token: TokenResponse) {
        #if canImport(Security)
        KeychainStore.shared.setFhirAccessToken(token.access_token, issuer: config.issuer)
        if let r = token.refresh_token {
            KeychainStore.shared.setFhirRefreshToken(r, issuer: config.issuer)
        }
        #endif
    }

    private func percentEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
