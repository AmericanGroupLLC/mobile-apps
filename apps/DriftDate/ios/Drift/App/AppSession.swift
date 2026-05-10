import Foundation
import Combine
import DriftCore

/// Top-level session: tracks current user + which screen the root should show.
@MainActor
final class AppSession: ObservableObject {

    enum State { case loading, needsOnboarding, ready }

    @Published private(set) var state: State = .loading
    @Published var currentProfile: Profile?

    private let auth = AuthService.shared
    private let profileService = ProfileService.shared

    func bootstrap() async {
        if let token = AuthService.shared.cachedToken() {
            SupabaseClient.shared?.setJWT(token)
            do {
                currentProfile = try await profileService.fetchMine()
                state = currentProfile == nil ? .needsOnboarding : .ready
            } catch {
                state = .needsOnboarding
            }
        } else {
            state = .needsOnboarding
        }
    }

    func onboardingFinished(profile: Profile) {
        currentProfile = profile
        state = .ready
    }

    func signOut() async {
        await auth.signOut()
        currentProfile = nil
        state = .needsOnboarding
    }
}
