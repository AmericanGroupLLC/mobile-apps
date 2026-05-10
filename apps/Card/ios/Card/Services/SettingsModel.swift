import SwiftUI

/// Persisted user settings. Single source of truth for theme, time-format,
/// and observability opt-ins. Values are stored in the App Group so the
/// Share Extension sees the same opt-in state.
@MainActor
final class SettingsModel: ObservableObject {
    static let shared = SettingsModel()

    private let defaults: UserDefaults
    private enum Key {
        static let onboarding   = "onboardingCompleted"
        static let twentyFour   = "use24Hour"
        static let theme        = "themeChoice"
        static let analytics    = "analyticsOptedIn"
        static let crash        = "crashOptedIn"
    }

    @Published var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Key.onboarding) } }
    @Published var use24Hour: Bool { didSet { defaults.set(use24Hour, forKey: Key.twentyFour) } }
    @Published var themeChoice: ThemeChoice { didSet { defaults.set(themeChoice.rawValue, forKey: Key.theme) } }
    @Published var analyticsOptedIn: Bool { didSet { defaults.set(analyticsOptedIn, forKey: Key.analytics) } }
    @Published var crashOptedIn: Bool { didSet { defaults.set(crashOptedIn, forKey: Key.crash) } }

    init() {
        let d = UserDefaults(suiteName: "group.com.americangroupllc.card") ?? .standard
        self.defaults = d
        self.onboardingCompleted = d.bool(forKey: Key.onboarding)
        self.use24Hour           = d.bool(forKey: Key.twentyFour)
        self.themeChoice         = ThemeChoice(rawValue: d.string(forKey: Key.theme) ?? "") ?? .system
        self.analyticsOptedIn    = d.bool(forKey: Key.analytics)
        self.crashOptedIn        = d.bool(forKey: Key.crash)
    }

    var colorScheme: ColorScheme? {
        switch themeChoice {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

enum ThemeChoice: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}
