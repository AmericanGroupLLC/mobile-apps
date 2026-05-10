import Foundation
import SwiftUI
import BuddyCore

/// User preferences. Persisted via `UserDefaults` so we don't need DataStore
/// or Core Data for v1.
@MainActor
final class SettingsModel: ObservableObject {
    @AppStorage("buddyplay.displayName") var displayName: String = "Player"
    @AppStorage("buddyplay.defaultGame") private var defaultGameRaw: String = GameKind.chess.rawValue
    @AppStorage("buddyplay.connectivityPref") private var connectivityPrefRaw: String = ConnectivityBridge.Preference.auto.rawValue
    @AppStorage("buddyplay.soundEnabled") var soundEnabled: Bool = true
    @AppStorage("buddyplay.hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("buddyplay.theme") private var themeRaw: String = "system"

    var defaultGame: GameKind {
        get { GameKind(rawValue: defaultGameRaw) ?? .chess }
        set { defaultGameRaw = newValue.rawValue }
    }

    var connectivityPreference: ConnectivityBridge.Preference {
        get { ConnectivityBridge.Preference(rawValue: connectivityPrefRaw) ?? .auto }
        set { connectivityPrefRaw = newValue.rawValue }
    }

    enum Theme: String, CaseIterable {
        case system, light, dark
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
    }

    var theme: Theme {
        get { Theme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
