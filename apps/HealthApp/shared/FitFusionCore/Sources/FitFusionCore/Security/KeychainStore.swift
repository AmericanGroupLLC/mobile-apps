import Foundation
#if canImport(Security)
import Security

/// PHI-grade Keychain wrapper for storing OAuth tokens (JWT, FHIR access /
/// refresh tokens, future MyChart issuer tokens) and any other small,
/// per-issuer secret. Backed by `kSecClassGenericPassword` with the
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` accessibility class so
/// the data is unavailable when the device is locked AND never restored to a
/// new device through iCloud Keychain or device backup.
///
/// **Why not UserDefaults?** UserDefaults is plaintext-on-disk inside the
/// app sandbox, which fails any HIPAA threat-model that includes a
/// jailbroken or otherwise rooted device. Keychain entries are encrypted
/// with the user's passcode-derived key.
///
/// One namespace per app bundle. Per-issuer scoping is done through the
/// `account` parameter (e.g. `"epic.sandbox.access_token"`).
public final class KeychainStore {

    public static let shared = KeychainStore()

    public enum Service {
        public static let auth     = "com.fitfusion.ios.auth"
        public static let fhir     = "com.fitfusion.ios.fhir"
        public static let insurance = "com.fitfusion.ios.insurance"
    }

    /// Default access control: data unlocks at first-unlock-after-boot and
    /// stays available, but is bound to this device (no iCloud Keychain
    /// sync, no migration to a restored device).
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    private init() {}

    // MARK: - Read / write / delete

    /// Returns true on success. Replaces any existing value for (service, account).
    @discardableResult
    public func set(_ value: String, service: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        // Delete any existing first; SecItemUpdate would be a single round
        // trip but adds branchy fallback logic, so we simplify.
        delete(service: service, account: account)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: Self.accessibility,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    public func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    @discardableResult
    public func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    public func deleteAll(service: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience for common app secrets

    /// MyHealth backend JWT — moved out of UserDefaults at first launch by
    /// `migrateLegacyJWTIfNeeded()`.
    public var jwt: String? {
        get { get(service: Service.auth, account: "jwt") }
        set {
            if let v = newValue { set(v, service: Service.auth, account: "jwt") }
            else { delete(service: Service.auth, account: "jwt") }
        }
    }

    public func setFhirAccessToken(_ token: String, issuer: String) {
        set(token, service: Service.fhir, account: "\(issuer).access_token")
    }
    public func fhirAccessToken(issuer: String) -> String? {
        get(service: Service.fhir, account: "\(issuer).access_token")
    }

    public func setFhirRefreshToken(_ token: String, issuer: String) {
        set(token, service: Service.fhir, account: "\(issuer).refresh_token")
    }
    public func fhirRefreshToken(issuer: String) -> String? {
        get(service: Service.fhir, account: "\(issuer).refresh_token")
    }

    public func clearFhir(issuer: String) {
        delete(service: Service.fhir, account: "\(issuer).access_token")
        delete(service: Service.fhir, account: "\(issuer).refresh_token")
    }

    /// One-time migration: if a legacy JWT is in `UserDefaults["token"]` (the
    /// pre-Care+ storage location used by APIClient.swift), copy it to the
    /// Keychain and remove the plaintext copy. Idempotent — safe to call on
    /// every cold start.
    public func migrateLegacyJWTIfNeeded() {
        if let legacy = UserDefaults.standard.string(forKey: "token"),
           !legacy.isEmpty,
           jwt == nil {
            jwt = legacy
        }
        // Only blank out the legacy slot once the Keychain copy is confirmed.
        if jwt != nil {
            UserDefaults.standard.removeObject(forKey: "token")
        }
    }
}
#endif
