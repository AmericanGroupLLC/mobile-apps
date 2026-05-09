import Foundation

/// A multi-week pre-built training plan composed of `ProgramDay`s. Each day
/// references exercises from `ExerciseLibrary` by id.
public struct WorkoutProgram: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let summary: String
    public let weeks: Int
    public let daysPerWeek: Int
    public let split: String        // e.g. "Push / Pull / Legs"
    public let level: ExerciseDifficulty
    public let days: [ProgramDay]

    public init(id: String, name: String, summary: String,
                weeks: Int, daysPerWeek: Int, split: String,
                level: ExerciseDifficulty, days: [ProgramDay]) {
        self.id = id
        self.name = name
        self.summary = summary
        self.weeks = weeks
        self.daysPerWeek = daysPerWeek
        self.split = split
        self.level = level
        self.days = days
    }
}

public struct ProgramDay: Codable, Identifiable, Hashable {
    public var id: String { name }
    public let name: String                        // "Push A", "Upper Day", etc.
    public let exerciseIds: [String]
    public let sets: Int
    public let repRange: String                    // "5", "8-10", "AMRAP", etc.
    public let restSeconds: Int

    public init(name: String, exerciseIds: [String],
                sets: Int, repRange: String, restSeconds: Int) {
        self.name = name
        self.exerciseIds = exerciseIds
        self.sets = sets
        self.repRange = repRange
        self.restSeconds = restSeconds
    }
}

public enum WorkoutPrograms {

    public static let all: [WorkoutProgram] = [pushPullLegs, upperLower, fullBody, beginnerStrength]

    public static func byId(_ id: String) -> WorkoutProgram? { all.first { $0.id == id } }

    public static let pushPullLegs = WorkoutProgram(
        id: "ppl",
        name: "Push / Pull / Legs",
        summary: "The classic 6-day split — push muscles together, pull muscles together, legs alone.",
        weeks: 8, daysPerWeek: 6, split: "Push / Pull / Legs",
        level: .intermediate,
        days: [
            ProgramDay(name: "Push A",
                       exerciseIds: ["bench-press", "ohp", "incline-db-press",
                                     "lateral-raise", "tricep-pushdown", "skullcrusher"],
                       sets: 4, repRange: "6-10", restSeconds: 90),
            ProgramDay(name: "Pull A",
                       exerciseIds: ["barbell-row", "pullup", "lat-pulldown",
                                     "rear-delt-fly", "barbell-curl", "hammer-curl"],
                       sets: 4, repRange: "6-10", restSeconds: 90),
            ProgramDay(name: "Legs A",
                       exerciseIds: ["back-squat", "rdl", "lunge",
                                     "hip-thrust", "calf-raise"],
                       sets: 4, repRange: "6-10", restSeconds: 120),
            ProgramDay(name: "Push B",
                       exerciseIds: ["dumbbell-press", "ohp", "lateral-raise",
                                     "tricep-pushdown", "pushup"],
                       sets: 3, repRange: "8-12", restSeconds: 75),
            ProgramDay(name: "Pull B",
                       exerciseIds: ["seated-cable-row", "lat-pulldown", "rear-delt-fly",
                                     "barbell-curl", "hammer-curl"],
                       sets: 3, repRange: "8-12", restSeconds: 75),
            ProgramDay(name: "Legs B",
                       exerciseIds: ["front-squat", "rdl", "goblet-squat",
                                     "hip-thrust", "calf-raise"],
                       sets: 3, repRange: "8-12", restSeconds: 90),
        ]
    )

    public static let upperLower = WorkoutProgram(
        id: "upper-lower",
        name: "Upper / Lower",
        summary: "Hit each half of the body twice per week — great balance of volume and recovery.",
        weeks: 8, daysPerWeek: 4, split: "Upper / Lower",
        level: .intermediate,
        days: [
            ProgramDay(name: "Upper A",
                       exerciseIds: ["bench-press", "barbell-row", "ohp",
                                     "pullup", "barbell-curl", "tricep-pushdown"],
                       sets: 4, repRange: "5-8", restSeconds: 120),
            ProgramDay(name: "Lower A",
                       exerciseIds: ["back-squat", "rdl", "lunge", "calf-raise", "plank"],
                       sets: 4, repRange: "5-8", restSeconds: 120),
            ProgramDay(name: "Upper B",
                       exerciseIds: ["incline-db-press", "lat-pulldown", "lateral-raise",
                                     "rear-delt-fly", "hammer-curl", "skullcrusher"],
                       sets: 3, repRange: "8-12", restSeconds: 75),
            ProgramDay(name: "Lower B",
                       exerciseIds: ["deadlift", "front-squat", "hip-thrust",
                                     "calf-raise", "hanging-leg-raise"],
                       sets: 3, repRange: "8-12", restSeconds: 90),
        ]
    )

    public static let fullBody = WorkoutProgram(
        id: "full-body",
        name: "Full Body 3x",
        summary: "Three full-body sessions per week — perfect when life is busy.",
        weeks: 6, daysPerWeek: 3, split: "Full Body",
        level: .beginner,
        days: [
            ProgramDay(name: "Day A",
                       exerciseIds: ["goblet-squat", "dumbbell-press", "barbell-row",
                                     "plank", "calf-raise"],
                       sets: 3, repRange: "8-10", restSeconds: 60),
            ProgramDay(name: "Day B",
                       exerciseIds: ["rdl", "pushup", "lat-pulldown",
                                     "lateral-raise", "russian-twist"],
                       sets: 3, repRange: "10-12", restSeconds: 60),
            ProgramDay(name: "Day C",
                       exerciseIds: ["lunge", "incline-db-press", "seated-cable-row",
                                     "hammer-curl", "tricep-pushdown"],
                       sets: 3, repRange: "8-10", restSeconds: 60),
        ]
    )

    public static let beginnerStrength = WorkoutProgram(
        id: "beginner-strength",
        name: "Beginner Strength",
        summary: "Linear progression on the big lifts — start light, add a small amount each session.",
        weeks: 12, daysPerWeek: 3, split: "Full Body Strength",
        level: .beginner,
        days: [
            ProgramDay(name: "Workout A",
                       exerciseIds: ["back-squat", "bench-press", "barbell-row"],
                       sets: 5, repRange: "5", restSeconds: 180),
            ProgramDay(name: "Workout B",
                       exerciseIds: ["back-squat", "ohp", "deadlift"],
                       sets: 5, repRange: "5", restSeconds: 180),
        ]
    )
}
