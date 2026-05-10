import Foundation

// MARK: - Muscle groups & body regions

public enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest, back, lats, traps, shoulders, biceps, triceps, forearms,
         core, obliques, lowerBack,
         glutes, quads, hamstrings, calves, adductors, abductors

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .chest:      return "Chest"
        case .back:       return "Back"
        case .lats:       return "Lats"
        case .traps:      return "Traps"
        case .shoulders:  return "Shoulders"
        case .biceps:     return "Biceps"
        case .triceps:    return "Triceps"
        case .forearms:   return "Forearms"
        case .core:       return "Core / Abs"
        case .obliques:   return "Obliques"
        case .lowerBack:  return "Lower Back"
        case .glutes:     return "Glutes"
        case .quads:      return "Quads"
        case .hamstrings: return "Hamstrings"
        case .calves:     return "Calves"
        case .adductors:  return "Adductors"
        case .abductors:  return "Abductors"
        }
    }

    /// Which side of the body silhouette the region renders on.
    public var view: BodyView {
        switch self {
        case .back, .lats, .traps, .lowerBack, .glutes, .hamstrings:
            return .back
        default:
            return .front
        }
    }
}

public enum BodyView: String, CaseIterable, Identifiable {
    case front, back
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

// MARK: - Equipment + difficulty

public enum Equipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case bodyweight, dumbbell, barbell, kettlebell, cable, machine, band, cardio, other

    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .bodyweight: return "Bodyweight"
        case .dumbbell:   return "Dumbbell"
        case .barbell:    return "Barbell"
        case .kettlebell: return "Kettlebell"
        case .cable:      return "Cable"
        case .machine:    return "Machine"
        case .band:       return "Band"
        case .cardio:     return "Cardio"
        case .other:      return "Other"
        }
    }
    public var systemImage: String {
        switch self {
        case .bodyweight: return "figure.cooldown"
        case .dumbbell:   return "dumbbell.fill"
        case .barbell:    return "figure.strengthtraining.traditional"
        case .kettlebell: return "figure.cross.training"
        case .cable:      return "cable.connector"
        case .machine:    return "gearshape.2.fill"
        case .band:       return "circle.dashed"
        case .cardio:     return "heart.fill"
        case .other:      return "questionmark.circle"
        }
    }
}

public enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable, Hashable {
    case beginner, intermediate, advanced
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

// MARK: - Exercise

public struct Exercise: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let primaryMuscles: [MuscleGroup]
    public let secondaryMuscles: [MuscleGroup]
    public let equipment: Equipment
    public let difficulty: ExerciseDifficulty
    public let instructions: [String]
    public let formTips: [String]
    /// Optional remote demo URL. The app falls back to an SF-Symbol animation
    /// when this is nil (so the library is fully usable offline).
    public let videoURL: URL?
    /// True when this is a stretch / mobility exercise rather than a lift.
    public let isStretch: Bool

    public init(id: String, name: String,
                primary: [MuscleGroup], secondary: [MuscleGroup] = [],
                equipment: Equipment, difficulty: ExerciseDifficulty,
                instructions: [String], formTips: [String],
                videoURL: URL? = nil, isStretch: Bool = false) {
        self.id = id
        self.name = name
        self.primaryMuscles = primary
        self.secondaryMuscles = secondary
        self.equipment = equipment
        self.difficulty = difficulty
        self.instructions = instructions
        self.formTips = formTips
        self.videoURL = videoURL
        self.isStretch = isStretch
    }
}

// MARK: - Library

public enum ExerciseLibrary {

    public static let exercises: [Exercise] = strength + cardio + stretches

    public static func filter(muscle: MuscleGroup? = nil,
                              equipment: Equipment? = nil,
                              difficulty: ExerciseDifficulty? = nil,
                              includeStretches: Bool = true) -> [Exercise] {
        exercises.filter { ex in
            if !includeStretches && ex.isStretch { return false }
            if let m = muscle, !ex.primaryMuscles.contains(m) && !ex.secondaryMuscles.contains(m) { return false }
            if let e = equipment, ex.equipment != e { return false }
            if let d = difficulty, ex.difficulty != d { return false }
            return true
        }
    }

    public static func search(_ query: String) -> [Exercise] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return exercises }
        return exercises.filter { $0.name.lowercased().contains(q) }
    }

    public static func byId(_ id: String) -> Exercise? {
        exercises.first { $0.id == id }
    }

    // MARK: - Strength

    private static let strength: [Exercise] = [
        // Chest
        Exercise(id: "bench-press", name: "Barbell Bench Press",
                 primary: [.chest], secondary: [.triceps, .shoulders],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: [
                    "Lie flat with eyes under the bar.",
                    "Grip slightly wider than shoulder-width.",
                    "Lower the bar to mid-chest with control.",
                    "Press up to lockout, exhaling on the way up.",
                 ],
                 formTips: ["Keep shoulder blades pinched.",
                            "Feet planted, slight arch in lower back.",
                            "Bar path is a slight diagonal — not straight up."]),
        Exercise(id: "dumbbell-press", name: "Dumbbell Bench Press",
                 primary: [.chest], secondary: [.triceps, .shoulders],
                 equipment: .dumbbell, difficulty: .beginner,
                 instructions: [
                    "Sit on bench with dumbbells on your thighs.",
                    "Kick them up as you lie back.",
                    "Press both dumbbells up over your chest.",
                    "Lower until upper arms are parallel to floor.",
                 ],
                 formTips: ["Don't clang the dumbbells together at the top.",
                            "Keep wrists stacked over elbows."]),
        Exercise(id: "pushup", name: "Push-up",
                 primary: [.chest], secondary: [.triceps, .core, .shoulders],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: [
                    "Hands slightly wider than shoulders.",
                    "Lower until chest is just above the floor.",
                    "Press back up, keeping a straight line head-to-heels.",
                 ],
                 formTips: ["Don't let hips sag.",
                            "Elbows track at 45° — not flared 90°."]),
        Exercise(id: "incline-db-press", name: "Incline Dumbbell Press",
                 primary: [.chest], secondary: [.shoulders, .triceps],
                 equipment: .dumbbell, difficulty: .intermediate,
                 instructions: ["Set bench to 30°.",
                                "Press dumbbells up over upper chest.",
                                "Lower with control to upper-chest height."],
                 formTips: ["Higher angle = more shoulder, less chest."]),

        // Back / lats
        Exercise(id: "pullup", name: "Pull-up",
                 primary: [.lats, .back], secondary: [.biceps, .forearms],
                 equipment: .bodyweight, difficulty: .intermediate,
                 instructions: [
                    "Hang from a bar with overhand grip, hands shoulder-width.",
                    "Pull yourself up until chin clears the bar.",
                    "Lower with full control to a dead hang.",
                 ],
                 formTips: ["Initiate from the lats, not the arms.",
                            "Engage core to avoid swinging."]),
        Exercise(id: "barbell-row", name: "Barbell Row",
                 primary: [.back, .lats], secondary: [.biceps, .lowerBack],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: [
                    "Hinge at the hips with knees slightly bent.",
                    "Pull the bar to your lower ribs.",
                    "Lower with control."],
                 formTips: ["Flat back the whole rep.", "Don't yank with your arms."]),
        Exercise(id: "lat-pulldown", name: "Lat Pulldown",
                 primary: [.lats], secondary: [.biceps, .back],
                 equipment: .cable, difficulty: .beginner,
                 instructions: ["Grip the bar wider than shoulders.",
                                "Pull to upper chest, drive elbows down.",
                                "Slowly let it rise back."],
                 formTips: ["Lean back about 15°.", "Don't shrug."]),
        Exercise(id: "seated-cable-row", name: "Seated Cable Row",
                 primary: [.back], secondary: [.biceps, .lats],
                 equipment: .cable, difficulty: .beginner,
                 instructions: ["Sit tall with knees soft.",
                                "Pull handle to navel, squeeze shoulder blades.",
                                "Extend arms with control."],
                 formTips: ["Keep torso upright — don't rock."]),

        // Shoulders
        Exercise(id: "ohp", name: "Overhead Press",
                 primary: [.shoulders], secondary: [.triceps, .core],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: ["Bar at collarbone height.",
                                "Press straight overhead, head moves through.",
                                "Lower to the front delts."],
                 formTips: ["Squeeze glutes to protect lower back.",
                            "Bar over mid-foot at lockout."]),
        Exercise(id: "lateral-raise", name: "Lateral Raise",
                 primary: [.shoulders],
                 equipment: .dumbbell, difficulty: .beginner,
                 instructions: ["Hold dumbbells at sides.",
                                "Raise arms out to shoulder height.",
                                "Lower slowly."],
                 formTips: ["Lead with the elbows, not the hands.",
                            "Keep a slight bend in the arms."]),
        Exercise(id: "rear-delt-fly", name: "Rear Delt Fly",
                 primary: [.shoulders, .back],
                 equipment: .dumbbell, difficulty: .beginner,
                 instructions: ["Hinge forward 45°.",
                                "Open arms wide like a hug in reverse.",
                                "Squeeze shoulder blades briefly at top."],
                 formTips: ["Light weight — form first."]),

        // Arms
        Exercise(id: "barbell-curl", name: "Barbell Curl",
                 primary: [.biceps], secondary: [.forearms],
                 equipment: .barbell, difficulty: .beginner,
                 instructions: ["Stand with shoulder-width grip.",
                                "Curl up keeping elbows at sides.",
                                "Lower under control."],
                 formTips: ["Don't swing the torso."]),
        Exercise(id: "hammer-curl", name: "Hammer Curl",
                 primary: [.biceps, .forearms],
                 equipment: .dumbbell, difficulty: .beginner,
                 instructions: ["Neutral grip (palms in).",
                                "Curl one arm at a time or together.",
                                "Lower slowly."],
                 formTips: ["Big forearm builder."]),
        Exercise(id: "tricep-pushdown", name: "Tricep Pushdown",
                 primary: [.triceps],
                 equipment: .cable, difficulty: .beginner,
                 instructions: ["Use a rope or straight bar.",
                                "Elbows pinned to ribs.",
                                "Press down until elbows lock, squeeze."],
                 formTips: ["Don't let the elbows drift forward."]),
        Exercise(id: "skullcrusher", name: "Skullcrusher",
                 primary: [.triceps],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: ["Lie on bench, bar over chest.",
                                "Bend at elbows, lower bar toward forehead.",
                                "Extend back to start."],
                 formTips: ["Upper arms perpendicular to the floor — keep them still."]),

        // Core
        Exercise(id: "plank", name: "Plank",
                 primary: [.core], secondary: [.shoulders, .glutes],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Forearms on floor, body in a straight line.",
                                "Hold for 30–60 s."],
                 formTips: ["Don't let hips sag or pike."]),
        Exercise(id: "hanging-leg-raise", name: "Hanging Leg Raise",
                 primary: [.core], secondary: [.forearms],
                 equipment: .bodyweight, difficulty: .advanced,
                 instructions: ["Hang from a bar.",
                                "Raise straight legs to parallel or higher.",
                                "Lower with control."],
                 formTips: ["No swinging — pause at the bottom."]),
        Exercise(id: "russian-twist", name: "Russian Twist",
                 primary: [.obliques, .core],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Sit, lean back ~45°.",
                                "Rotate side to side, optionally with a weight."],
                 formTips: ["Keep chest tall."]),

        // Legs
        Exercise(id: "back-squat", name: "Back Squat",
                 primary: [.quads, .glutes], secondary: [.hamstrings, .core, .lowerBack],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: ["Bar across upper back.",
                                "Sit between your hips.",
                                "Drive through mid-foot to stand."],
                 formTips: ["Knees track over toes.",
                            "Brace core like you're about to be punched."]),
        Exercise(id: "front-squat", name: "Front Squat",
                 primary: [.quads], secondary: [.glutes, .core],
                 equipment: .barbell, difficulty: .advanced,
                 instructions: ["Bar across front delts.",
                                "Elbows high.",
                                "Squat upright to depth."],
                 formTips: ["Keep elbows up — bar will roll if they drop."]),
        Exercise(id: "goblet-squat", name: "Goblet Squat",
                 primary: [.quads, .glutes],
                 equipment: .dumbbell, difficulty: .beginner,
                 instructions: ["Hold a single dumbbell at chest.",
                                "Squat between heels.",
                                "Stand back up tall."],
                 formTips: ["Great learning squat."]),
        Exercise(id: "deadlift", name: "Deadlift",
                 primary: [.hamstrings, .glutes, .lowerBack],
                 secondary: [.back, .core, .forearms],
                 equipment: .barbell, difficulty: .advanced,
                 instructions: ["Bar over mid-foot.",
                                "Hinge, grip just outside knees.",
                                "Drive the floor away."],
                 formTips: ["Bar stays in contact with the legs.",
                            "Lock out hips and knees together."]),
        Exercise(id: "rdl", name: "Romanian Deadlift",
                 primary: [.hamstrings, .glutes], secondary: [.lowerBack],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: ["Soft knees, hinge at hips.",
                                "Lower bar along legs to mid-shin.",
                                "Drive hips through to stand."],
                 formTips: ["You should feel a stretch in the hamstrings."]),
        Exercise(id: "lunge", name: "Walking Lunge",
                 primary: [.quads, .glutes], secondary: [.hamstrings, .core],
                 equipment: .dumbbell, difficulty: .beginner,
                 instructions: ["Step forward, lower back knee toward floor.",
                                "Drive off front foot, step through to next lunge."],
                 formTips: ["Front shin near vertical."]),
        Exercise(id: "hip-thrust", name: "Hip Thrust",
                 primary: [.glutes], secondary: [.hamstrings],
                 equipment: .barbell, difficulty: .intermediate,
                 instructions: ["Upper back on bench, bar over hips.",
                                "Drive hips up to a glute-squeeze lockout.",
                                "Lower with control."],
                 formTips: ["Chin tucked, ribs down."]),
        Exercise(id: "calf-raise", name: "Standing Calf Raise",
                 primary: [.calves],
                 equipment: .machine, difficulty: .beginner,
                 instructions: ["Press up onto toes.",
                                "Pause at top, lower until full stretch."],
                 formTips: ["Slow eccentric for size."]),
    ]

    // MARK: - Cardio

    private static let cardio: [Exercise] = [
        Exercise(id: "treadmill-run", name: "Treadmill Run",
                 primary: [.quads, .calves, .hamstrings], secondary: [.glutes, .core],
                 equipment: .cardio, difficulty: .beginner,
                 instructions: ["Warm up walking 3 min.",
                                "Run at a conversational pace.",
                                "Cool down walking 3 min."],
                 formTips: ["Land midfoot under your hips."]),
        Exercise(id: "rower", name: "Rowing Machine",
                 primary: [.back, .quads, .glutes], secondary: [.core, .biceps],
                 equipment: .cardio, difficulty: .beginner,
                 instructions: ["Drive with the legs first.",
                                "Lean back slightly.",
                                "Pull handle to ribs."],
                 formTips: ["Sequence: legs → back → arms (then reverse)."]),
        Exercise(id: "jump-rope", name: "Jump Rope",
                 primary: [.calves], secondary: [.shoulders, .core],
                 equipment: .cardio, difficulty: .beginner,
                 instructions: ["Wrists do the turning, not the arms.",
                                "Small bounces, soft landing."],
                 formTips: ["Stay on the balls of your feet."]),
    ]

    // MARK: - Stretches / mobility

    private static let stretches: [Exercise] = [
        Exercise(id: "child-pose", name: "Child's Pose",
                 primary: [.lowerBack], secondary: [.lats, .shoulders],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Kneel, sit hips back to heels.",
                                "Reach arms forward, forehead to floor.",
                                "Breathe slowly for 30–60 s."],
                 formTips: ["Great post-deadlift decompression."],
                 isStretch: true),
        Exercise(id: "hip-flexor-stretch", name: "Hip Flexor Stretch",
                 primary: [.quads, .glutes],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Half-kneel with one foot forward.",
                                "Tuck pelvis, push hips forward.",
                                "Hold 30 s each side."],
                 formTips: ["Squeeze the back glute to deepen the stretch."],
                 isStretch: true),
        Exercise(id: "pigeon-pose", name: "Pigeon Pose",
                 primary: [.glutes, .hamstrings],
                 equipment: .bodyweight, difficulty: .intermediate,
                 instructions: ["Front shin angled, back leg extended.",
                                "Lower torso forward over front leg.",
                                "Hold 60 s each side."],
                 formTips: ["Keep front foot flexed to protect the knee."],
                 isStretch: true),
        Exercise(id: "thread-needle", name: "Thread the Needle",
                 primary: [.back], secondary: [.shoulders],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["From all-fours, slide one arm under the other.",
                                "Rest shoulder + ear on the floor.",
                                "Hold 30 s each side."],
                 formTips: ["Great thoracic mobility cue."],
                 isStretch: true),
        Exercise(id: "couch-stretch", name: "Couch Stretch",
                 primary: [.quads], secondary: [.glutes],
                 equipment: .bodyweight, difficulty: .intermediate,
                 instructions: ["Back foot up on couch / bench.",
                                "Front foot forward in lunge.",
                                "Tuck pelvis, hold 60 s each side."],
                 formTips: ["Brutal but effective for tight quads."],
                 isStretch: true),
        Exercise(id: "downward-dog", name: "Downward Dog",
                 primary: [.hamstrings, .calves], secondary: [.shoulders, .lats],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Inverted V shape, hands and feet planted.",
                                "Press chest toward thighs.",
                                "Pedal feet to deepen the calf stretch."],
                 formTips: ["Bend knees if hamstrings are tight."],
                 isStretch: true),
        Exercise(id: "cat-cow", name: "Cat–Cow",
                 primary: [.lowerBack], secondary: [.core],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["From all-fours, alternate spinal flexion + extension.",
                                "Inhale into cow (belly down), exhale into cat (round)."],
                 formTips: ["Slow tempo — match the breath."],
                 isStretch: true),
        Exercise(id: "shoulder-doorway", name: "Doorway Pec Stretch",
                 primary: [.chest], secondary: [.shoulders],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Forearm on doorframe, elbow at shoulder height.",
                                "Step forward to open the chest.",
                                "Hold 30 s each side."],
                 formTips: ["Square your shoulders to feel it."],
                 isStretch: true),
        Exercise(id: "calf-wall", name: "Calf Wall Stretch",
                 primary: [.calves],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Hands on wall, one leg back, heel down.",
                                "Lean into the wall.",
                                "Hold 30 s each side."],
                 formTips: ["Bend the back knee for a deeper soleus stretch."],
                 isStretch: true),
        Exercise(id: "neck-rolls", name: "Neck Rolls",
                 primary: [.traps],
                 equipment: .bodyweight, difficulty: .beginner,
                 instructions: ["Slow circles each direction, 5 reps.",
                                "Drop ear to shoulder, hold 15 s each side."],
                 formTips: ["Move slowly — never force range."],
                 isStretch: true),
    ]
}
