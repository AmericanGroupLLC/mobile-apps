import Foundation
import DriftCore

/// Stub Supabase client singleton wired up at app start.
extension SupabaseClient {
    static var shared: SupabaseClient? = SupabaseClient.fromBundle()
}

/// Phone-OTP auth via Supabase. Skeleton — production would use the
/// Supabase Auth REST endpoints + secure storage for the JWT.
final class AuthService {
    static let shared = AuthService()

    private let tokenKey = "drift.jwt"

    func cachedToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    func sendOTP(toPhone phone: String) async throws { /* POST /auth/v1/otp */ }

    func verifyOTP(phone: String, code: String) async throws {
        // POST /auth/v1/verify -> token
        let token = "stub-token-for-\(phone)"
        UserDefaults.standard.set(token, forKey: tokenKey)
        SupabaseClient.shared?.setJWT(token)
    }

    func signOut() async {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        SupabaseClient.shared?.setJWT(nil)
    }
}
