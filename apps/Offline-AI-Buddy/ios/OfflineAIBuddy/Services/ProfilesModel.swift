import Foundation
import BuddyAICore

/// App-side wrapper around `BuddyAICore.ProfilesStore`. Tracks the
/// currently active profile + persists changes. PIN-locked switches
/// from Kid → Adult are enforced by the ChatScreen / Settings before
/// calling `setActive(...)`.
@MainActor
final class ProfilesModel: ObservableObject {

    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var activeProfileId: UUID?
    @Published var defaultLanguage: Language = .en

    private let store: ProfilesStore

    init() {
        self.store = try! ProfilesStore()
        self.profiles = store.loadAll()
        self.activeProfileId = profiles.first?.id
    }

    var activeProfile: Profile? {
        profiles.first { $0.id == activeProfileId }
    }

    func add(name: String, kind: Profile.Kind, pin: String?) throws {
        var p = Profile(name: name, kind: kind)
        if kind == .kidSafe, let pin {
            let salt = ProfilesStore.newSaltHex()
            p.pinSalt = salt
            p.pinHash = ProfilesStore.pbkdf2Hex(pin: pin, saltHex: salt)
        }
        try store.add(p)
        profiles = store.loadAll()
        if activeProfileId == nil { activeProfileId = p.id }
    }

    func remove(_ profile: Profile) throws {
        try store.remove(id: profile.id)
        profiles = store.loadAll()
        if activeProfileId == profile.id { activeProfileId = profiles.first?.id }
    }

    func setActive(_ profile: Profile) {
        activeProfileId = profile.id
    }

    /// Validate a PIN before allowing a Kid → Adult switch.
    func verify(pin: String, for profile: Profile) -> Bool {
        (try? store.verify(pin: pin, for: profile.id)) ?? false
    }
}
