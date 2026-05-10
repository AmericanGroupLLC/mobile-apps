import AppIntents
import Foundation
import FitFusionCore

// MARK: - Start Workout
@available(iOS 17.0, *)
struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Workout"
    static let description = IntentDescription("Start a MyHealth workout from the library.")
    static var openAppWhenRun: Bool { true }
    static var isDiscoverable: Bool { true }

    @Parameter(title: "Workout") var workoutName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$workoutName) workout in MyHealth")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let template = WorkoutLibrary.templates.first {
            workoutName.flatMap { name in
                $0.name.localizedCaseInsensitiveContains(name)
            } ?? false
        } ?? WorkoutLibrary.templates.first!

        await WorkoutScheduler.shared.schedule(template: template, at: Date())
        return .result(dialog: "Sent \(template.name) to your Watch — open the Workout app.")
    }
}

// MARK: - Start Run
@available(iOS 17.0, *)
struct StartRunIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Run"
    static let description = IntentDescription("Start an outdoor run.")
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Surface to the user in the Run tab; actual run is started on the Watch.
        return .result(dialog: "Open your Apple Watch and start the run from the MyHealth Run tab. 🏃")
    }
}

// MARK: - Log Meal
@available(iOS 17.0, *)
struct LogMealIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Meal"
    static let description = IntentDescription("Log a meal in MyHealth.")
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Meal name") var name: String
    @Parameter(title: "Calories", default: 400) var kcal: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$name) at \(\.$kcal) calories in MyHealth")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            _ = try await APIClient.shared.logMeal(name: name, kcal: kcal,
                                                   protein: 0, carbs: 0, fat: 0,
                                                   barcode: nil)
            return .result(dialog: "Logged \(name) (\(Int(kcal)) kcal) 🍽")
        } catch {
            return .result(dialog: "Couldn't log meal: \(error.localizedDescription)")
        }
    }
}

// MARK: - Log Meal Photo
@available(iOS 17.0, *)
struct LogMealPhotoIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Meal Photo"
    static let description = IntentDescription("Open MyHealth to snap a meal photo for AI recognition.")
    static var openAppWhenRun: Bool { true }
    static var isDiscoverable: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Open the Eat tab and tap Snap Meal — MyHealth will recognize it on-device. 🍽")
    }
}

// MARK: - Join Shared Workout
@available(iOS 17.0, *)
struct JoinSharedWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Join Shared Workout"
    static let description = IntentDescription("Join a friend's SharePlay workout session in MyHealth.")
    static var openAppWhenRun: Bool { true }
    static var isDiscoverable: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Open the Social tab and accept your friend's invite. 🤝")
    }
}

// MARK: - Shortcuts surfacing
@available(iOS 17.0, *)
struct FitFusionShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start a workout in \(.applicationName)",
                "Begin training in \(.applicationName)",
            ],
            shortTitle: "Start Workout",
            systemImageName: "figure.strengthtraining.traditional"
        )
        AppShortcut(
            intent: StartRunIntent(),
            phrases: [
                "Start a run in \(.applicationName)",
                "Go for a run with \(.applicationName)",
            ],
            shortTitle: "Start Run",
            systemImageName: "figure.run"
        )
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log a meal in \(.applicationName)",
                "Log \(\.$name) in \(.applicationName)",
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: LogMealPhotoIntent(),
            phrases: [
                "Snap a meal in \(.applicationName)",
                "Recognize my meal in \(.applicationName)",
            ],
            shortTitle: "Snap Meal",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: JoinSharedWorkoutIntent(),
            phrases: [
                "Join shared workout in \(.applicationName)",
                "Accept SharePlay workout in \(.applicationName)",
            ],
            shortTitle: "Join Shared Workout",
            systemImageName: "person.2.fill"
        )
    }
}
