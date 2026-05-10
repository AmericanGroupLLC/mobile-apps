import AppIntents
import Foundation
import FitFusionCore

// MARK: - Log Water
@available(iOS 16.0, watchOS 9.0, *)
struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"
    static let description = IntentDescription("Log a water intake amount in ml.")

    static var openAppWhenRun: Bool { false }
    static var isDiscoverable: Bool { true }

    @Parameter(title: "Amount (ml)", default: 250,
               inclusiveRange: (50, 2000))
    var amountML: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amountML) ml of water")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            _ = try await APIClient.shared.logMetric(type: "water", value: amountML, unit: "ml")
            await HealthKitManager.shared.writeWater(ml: amountML)
            return .result(dialog: "Logged \(Int(amountML)) ml of water 💧")
        } catch {
            return .result(dialog: "Couldn't log water: \(error.localizedDescription)")
        }
    }
}

// MARK: - Log Weight
@available(iOS 16.0, watchOS 9.0, *)
struct LogWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Weight"
    static let description = IntentDescription("Log your current body weight in kg.")

    static var openAppWhenRun: Bool { false }
    static var isDiscoverable: Bool { true }

    @Parameter(title: "Weight (kg)", default: 70,
               inclusiveRange: (20, 250))
    var weightKG: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log my weight as \(\.$weightKG) kg")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            _ = try await APIClient.shared.logMetric(type: "weight", value: weightKG, unit: "kg")
            await HealthKitManager.shared.writeWeight(kg: weightKG)
            return .result(dialog: "Logged \(String(format: "%.1f", weightKG)) kg ⚖️")
        } catch {
            return .result(dialog: "Couldn't log weight: \(error.localizedDescription)")
        }
    }
}

// MARK: - Log Mood
@available(iOS 16.0, watchOS 9.0, *)
enum MoodOption: String, AppEnum {
    case awful, low, okay, good, great
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Mood"
    static var caseDisplayRepresentations: [MoodOption: DisplayRepresentation] = [
        .awful: "Awful 😞",
        .low:   "Low 🙁",
        .okay:  "Okay 😐",
        .good:  "Good 🙂",
        .great: "Great 😄",
    ]
    var value: Int {
        switch self {
        case .awful: 1; case .low: 2; case .okay: 3; case .good: 4; case .great: 5
        }
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct LogMoodIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Mood"
    static let description = IntentDescription("Capture how you're feeling on a 5-point scale.")

    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Mood", default: .good)
    var mood: MoodOption

    static var parameterSummary: some ParameterSummary {
        Summary("Log my mood as \(\.$mood)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            _ = try await APIClient.shared.logMetric(type: "mood", value: Double(mood.value), unit: "1-5")
            return .result(dialog: "Got it — logged your mood as \(mood.rawValue) ✨")
        } catch {
            return .result(dialog: "Couldn't log mood: \(error.localizedDescription)")
        }
    }
}

// MARK: - Sync Now (manual)
@available(iOS 16.0, watchOS 9.0, *)
struct SyncHealthKitIntent: AppIntent {
    static let title: LocalizedStringResource = "Sync HealthKit"
    static let description = IntentDescription("Pull recent steps, sleep, weight, and heart rate from HealthKit.")
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await HealthKitManager.shared.startObservers()
        return .result(dialog: "Syncing your latest health data 🔄")
    }
}

// MARK: - Shortcuts surfacing
@available(iOS 16.0, watchOS 9.0, *)
struct HealthAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Log \(\.$amountML) milliliters of water in \(.applicationName)",
                "Add water to \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: LogWeightIntent(),
            phrases: [
                "Log weight in \(.applicationName)",
                "Log my weight in \(.applicationName)"
            ],
            shortTitle: "Log Weight",
            systemImageName: "scalemass.fill"
        )
        AppShortcut(
            intent: LogMoodIntent(),
            phrases: [
                "Log mood in \(.applicationName)",
                "Log my mood in \(.applicationName)",
                "How I'm feeling in \(.applicationName)"
            ],
            shortTitle: "Log Mood",
            systemImageName: "face.smiling.fill"
        )
        AppShortcut(
            intent: SyncHealthKitIntent(),
            phrases: ["Sync \(.applicationName)", "Pull data into \(.applicationName)"],
            shortTitle: "Sync HealthKit",
            systemImageName: "arrow.triangle.2.circlepath"
        )
    }
}
