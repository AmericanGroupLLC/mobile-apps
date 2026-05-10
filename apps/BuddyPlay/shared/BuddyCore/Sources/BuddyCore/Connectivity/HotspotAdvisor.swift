import Foundation

/// UI-side helper. Neither iOS nor Android exposes a programmatic API to
/// toggle the personal hotspot in user-installable apps. This type returns
/// human-readable instruction strings the lobby surfaces.
public enum HotspotAdvisor {
    public static func enableInstructions(for platform: Peer.Platform) -> String {
        switch platform {
        case .ios:
            return """
            1. Open Settings → Personal Hotspot.
            2. Toggle "Allow Others to Join" on.
            3. Note the network name + password.
            4. Have your friend join that network from their Wi-Fi settings.
            5. Come back to BuddyPlay — discovery will resume automatically.
            """
        case .android:
            return """
            1. Open Settings → Network & internet → Hotspot & tethering.
            2. Tap "Wi-Fi hotspot" → toggle on.
            3. Note the network name + password.
            4. Have your friend join that network from their Wi-Fi settings.
            5. Come back to BuddyPlay — discovery will resume automatically.
            """
        }
    }

    public static let title = "Use your phone's hotspot"
    public static let subtitle = "BuddyPlay can't toggle this for you (Apple's + Google's rules), but the steps are short."
}
