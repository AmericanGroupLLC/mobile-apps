import SwiftUI

/// Care+ semantic design tokens.
///
/// Each of the four primary tabs (Care · Diet · Train · Workout) gets its own
/// accent color so the app reads as four product surfaces under one shell.
/// Surface and on-surface tokens are derived from `Color`'s system semantic
/// colors so dark mode "just works" without per-token overrides.
///
/// SF Symbols ↔ Material Icons mapping reference (kept here so iOS + Android
/// stay in sync visually; do not change one without updating the other):
///
///   Tab        | SF Symbol                       | Material Icon
///   -----------|----------------------------------|--------------------------------
///   Care       | "heart.text.square"              | Icons.Filled.Favorite
///   Diet       | "fork.knife"                     | Icons.Filled.Restaurant
///   Train      | "figure.strengthtraining.traditional" | Icons.Filled.FitnessCenter
///   Workout    | "figure.run"                     | Icons.Filled.DirectionsRun
///   Profile    | "person.crop.circle"             | Icons.Filled.AccountCircle
///   Bell/News  | "bell.fill"                      | Icons.Filled.Notifications
///   MyChart    | "cross.case.fill"                | Icons.Filled.MedicalServices
///   Insurance  | "creditcard.fill"                | Icons.Filled.CreditCard
///   Doctor     | "stethoscope"                    | Icons.Filled.LocalHospital
///   Standup    | "figure.stand"                   | Icons.Filled.AirlineSeatReclineExtra
///   RPE        | "gauge.with.dots.needle.67percent" | Icons.Filled.Speed
public enum CarePlusPalette {
    // ─── Tab accents ─────────────────────────────────────────────────────
    /// Care tab — clinical blue, conveys medical / trust.
    public static let careBlue = Color(red: 0.18, green: 0.45, blue: 0.85)
    /// Diet tab — warm coral, food / appetite.
    public static let dietCoral = Color(red: 0.98, green: 0.40, blue: 0.45)
    /// Train tab — energetic green, growth.
    public static let trainGreen = Color(red: 0.21, green: 0.78, blue: 0.39)
    /// Workout tab — vibrant pink, exertion / heart-rate.
    public static let workoutPink = Color(red: 0.98, green: 0.29, blue: 0.55)

    // ─── Surface tokens (auto-adapt to dark mode) ────────────────────────
    public static let surface: Color = Color(.systemBackground)
    public static let surfaceElevated: Color = Color(.secondarySystemBackground)
    public static let onSurface: Color = Color(.label)
    public static let onSurfaceMuted: Color = Color(.secondaryLabel)
    public static let divider: Color = Color(.separator)

    // ─── Status tokens ───────────────────────────────────────────────────
    public static let success = Color(red: 0.12, green: 0.72, blue: 0.36)
    public static let warning = Color(red: 0.96, green: 0.62, blue: 0.10)
    public static let danger = Color(red: 0.92, green: 0.23, blue: 0.30)
    public static let info = Color(red: 0.20, green: 0.55, blue: 0.92)
}

/// Spacing scale (4-pt grid).
public enum CarePlusSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// Corner radius scale.
public enum CarePlusRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 18
    public static let pill: CGFloat = 999
}

/// Typography scale. Built on SF Pro through `Font.system`. Each token is a
/// semantic name (not a size); use these instead of raw `.font(.system(...))`
/// calls so future weight / size adjustments are a single-file change.
public enum CarePlusType {
    public static let titleXL: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    public static let title: Font = .system(.title2, design: .rounded, weight: .bold)
    public static let titleSM: Font = .system(.title3, design: .rounded, weight: .semibold)
    public static let body: Font = .system(.body)
    public static let bodyEm: Font = .system(.body, weight: .semibold)
    public static let caption: Font = .system(.caption)
    public static let captionEm: Font = .system(.caption, weight: .semibold)
}

/// Convenience: per-tab accent lookup from a stable string key, used by
/// shared components (header pill, ComingSoon badge, etc.) that are tab-aware.
public enum CarePlusTab: String, CaseIterable, Hashable, Sendable {
    case care, diet, train, workout

    public var accent: Color {
        switch self {
        case .care:    return CarePlusPalette.careBlue
        case .diet:    return CarePlusPalette.dietCoral
        case .train:   return CarePlusPalette.trainGreen
        case .workout: return CarePlusPalette.workoutPink
        }
    }

    public var label: String {
        switch self {
        case .care: return "Care"
        case .diet: return "Diet"
        case .train: return "Train"
        case .workout: return "Workout"
        }
    }

    public var symbol: String {
        switch self {
        case .care:    return "heart.text.square"
        case .diet:    return "fork.knife"
        case .train:   return "figure.strengthtraining.traditional"
        case .workout: return "figure.run"
        }
    }
}
