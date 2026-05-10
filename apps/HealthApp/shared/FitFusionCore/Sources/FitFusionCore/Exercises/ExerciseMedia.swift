import Foundation

// MARK: - Exercise media + medical safety map
//
// The Exercise model itself stays small and offline-first. This file maps
// each exercise ID to:
//   * an animated demo URL (GIF / short MP4) — lazy-loaded by the UI
//   * a "cautions" set: conditions for which the exercise is risky
//   * a "benefits" set: conditions where the exercise is encouraged
//
// Media URLs point at the marketing-site CDN (GitHub Pages) so the app stays
// lightweight — nothing is bundled. AsyncImage falls back to the SF Symbol
// when the URL 404s, so a missing GIF never breaks the screen.

public enum ExerciseMedia {

    /// Base URL for hosted demo GIFs. Override with a build-time env var
    /// `EXERCISE_MEDIA_BASE_URL` if you self-host the assets.
    public static let mediaBaseURL: URL = {
        if let env = ProcessInfo.processInfo.environment["EXERCISE_MEDIA_BASE_URL"],
           let url = URL(string: env) {
            return url
        }
        return URL(string: "https://americangroupllc.github.io/HealthApp/assets/exercises")!
    }()

    /// Returns the demo animated GIF URL for an exercise (may not exist).
    public static func gifURL(for exerciseId: String) -> URL {
        mediaBaseURL.appendingPathComponent("\(exerciseId).gif")
    }

    /// Returns the still-thumbnail URL (used while the GIF is loading).
    public static func thumbnailURL(for exerciseId: String) -> URL {
        mediaBaseURL.appendingPathComponent("\(exerciseId).jpg")
    }

    // MARK: - Safety maps (curated heuristic — NOT medical advice)

    /// Conditions for which the exercise is contraindicated or risky.
    /// When the user has any of these, the exercise is hidden from
    /// "Recommended for you" and shown with a caution banner if they
    /// open the detail screen.
    public static let cautions: [String: Set<HealthCondition>] = [
        // Heavy compound lifts — high blood-pressure spike, cardiac strain
        "back-squat":           [.hypertension, .heartCondition, .pregnancy, .osteoporosis, .kneeInjury, .backPain],
        "front-squat":          [.hypertension, .heartCondition, .pregnancy, .kneeInjury, .backPain],
        "deadlift":             [.hypertension, .heartCondition, .pregnancy, .backPain, .osteoporosis],
        "rdl":                  [.backPain, .pregnancy, .osteoporosis],
        "bench-press":          [.shoulderInjury, .heartCondition],
        "ohp":                  [.shoulderInjury, .hypertension, .heartCondition],
        "pullup":               [.shoulderInjury, .pregnancy, .osteoporosis],
        "skullcrusher":         [.shoulderInjury],
        // High-impact / jumping
        "jump-rope":            [.kneeInjury, .ankleInjury, .pregnancy, .heartCondition],
        "treadmill-run":        [.kneeInjury, .ankleInjury, .heartCondition, .obesity],
        // Inversions / Valsalva — caution for hypertension + pregnancy
        "downward-dog":         [.hypertension, .pregnancy],
        "hanging-leg-raise":    [.shoulderInjury, .backPain, .pregnancy],
        // Knee-flexion intensive
        "lunge":                [.kneeInjury, .pregnancy],
        "goblet-squat":         [.kneeInjury, .pregnancy, .backPain],
        "couch-stretch":        [.kneeInjury],
        "pigeon-pose":          [.kneeInjury, .pregnancy],
    ]

    /// Conditions for which the exercise is particularly beneficial.
    /// Used to *promote* an exercise in suggestions when the user has
    /// declared the condition (subject to it not also being in cautions).
    public static let benefits: [String: Set<HealthCondition>] = [
        // Mobility — back / hip pain
        "child-pose":           [.backPain],
        "cat-cow":              [.backPain, .pregnancy],
        "thread-needle":        [.backPain, .shoulderInjury],
        "hip-flexor-stretch":   [.backPain],
        // Low-impact cardio for hypertension / heart / obesity / diabetes
        "rower":                [.hypertension, .obesity, .diabetesT2],
        // Bone density (gentle weight-bearing) — osteoporosis (general activity helps; AVOID heavy axial)
        "lateral-raise":        [.osteoporosis],
        "calf-raise":           [.osteoporosis],
        // Glute activation — helps lower back pain
        "hip-thrust":           [.backPain],
        // Beginner-friendly upper body
        "pushup":               [.diabetesT2],
        "dumbbell-press":       [.diabetesT2, .obesity],
        // Asthma-friendly low-intensity
        "neck-rolls":           [.asthma],
        "shoulder-doorway":     [.asthma],
    ]

    /// Returns true when the exercise is safe (none of the user's conditions
    /// appear in the caution list).
    public static func isSafe(_ exerciseId: String,
                              for conditions: Set<HealthCondition>) -> Bool {
        guard let bad = cautions[exerciseId] else { return true }
        return bad.intersection(conditions).isEmpty
    }

    /// Returns conditions the user has that this exercise warns against.
    public static func conflictingConditions(_ exerciseId: String,
                                             for conditions: Set<HealthCondition>) -> Set<HealthCondition> {
        (cautions[exerciseId] ?? []).intersection(conditions)
    }

    /// Returns conditions the user has that this exercise actively helps.
    public static func beneficialFor(_ exerciseId: String,
                                     conditions: Set<HealthCondition>) -> Set<HealthCondition> {
        (benefits[exerciseId] ?? []).intersection(conditions)
    }
}

// MARK: - Library convenience

extension ExerciseLibrary {

    /// Filter the library by user health conditions. Unsafe exercises are
    /// dropped; beneficial ones are sorted to the top.
    public static func recommended(
        for conditions: Set<HealthCondition>,
        muscle: MuscleGroup? = nil,
        equipment: Equipment? = nil
    ) -> [Exercise] {
        let base = filter(muscle: muscle, equipment: equipment)
        let safe = base.filter { ExerciseMedia.isSafe($0.id, for: conditions) }
        return safe.sorted { a, b in
            let ab = ExerciseMedia.beneficialFor(a.id, conditions: conditions).count
            let bb = ExerciseMedia.beneficialFor(b.id, conditions: conditions).count
            return ab > bb
        }
    }
}
