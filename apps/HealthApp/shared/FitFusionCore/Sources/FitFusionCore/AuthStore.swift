import Foundation
import SwiftUI

@MainActor
public final class AuthStore: ObservableObject {
    @Published public var user: User?
    @Published public var isAuthenticated: Bool = false
    @Published public var isGuest: Bool = false
    @Published public var loading: Bool = false
    @Published public var errorMessage: String?

    public static let didOnboardKey = "didOnboard"
    private static let guestKey = "isGuest"

    public init() {
        // Restore guest mode first \u{2014} preserved across launches.
        if UserDefaults.standard.bool(forKey: Self.guestKey) {
            self.isGuest = true
            self.isAuthenticated = true
            return
        }
        // Otherwise restore JWT session if present.
        if let data = UserDefaults.standard.data(forKey: "user"),
           let cached = try? JSONDecoder().decode(User.self, from: data),
           UserDefaults.standard.string(forKey: "token") != nil {
            self.user = cached
            self.isAuthenticated = true
        }
    }

    /// Skip backend auth entirely. The app then runs against on-device
    /// CoreData / CloudKit only; the optional backend can still be opted into
    /// later via `startCloudSync(...)`.
    public func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: Self.guestKey)
        APIClient.shared.setGuest(true)
        self.isGuest = true
        self.isAuthenticated = true
    }

    public func login(email: String, password: String) async {
        loading = true; errorMessage = nil
        defer { loading = false }
        do {
            let r = try await APIClient.shared.login(email: email, password: password)
            promoteFromGuest()
            persist(user: r.user)
        } catch let e as APIError {
            errorMessage = e.error
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func register(name: String, email: String, password: String) async {
        loading = true; errorMessage = nil
        defer { loading = false }
        do {
            let r = try await APIClient.shared.register(name: name, email: email, password: password)
            promoteFromGuest()
            persist(user: r.user)
        } catch let e as APIError {
            errorMessage = e.error
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Convert a guest into a logged-in user without losing any local data
    /// (CoreData stays exactly where it was; we only flip the auth state).
    public func startCloudSync(email: String, password: String) async {
        await login(email: email, password: password)
    }

    public func logout() {
        APIClient.shared.setToken(nil)
        APIClient.shared.setGuest(false)
        UserDefaults.standard.removeObject(forKey: "user")
        UserDefaults.standard.removeObject(forKey: Self.guestKey)
        user = nil
        isAuthenticated = false
        isGuest = false
    }

    private func promoteFromGuest() {
        if isGuest {
            UserDefaults.standard.removeObject(forKey: Self.guestKey)
            APIClient.shared.setGuest(false)
            isGuest = false
        }
    }

    private func persist(user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "user")
        }
        self.user = user
        self.isAuthenticated = true
    }
}
