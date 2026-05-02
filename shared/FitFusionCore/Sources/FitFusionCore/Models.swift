import Foundation

public struct User: Codable, Identifiable, Hashable {
    public let id: Int
    public let email: String
    public let name: String

    public init(id: Int, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}

public struct AuthResponse: Codable {
    public let user: User
    public let token: String
}

public struct ProfileResponse: Codable {
    public let user: User
    public let profile: Profile
    public let bmi: BMI?
}

public struct Profile: Codable {
    public var age: Int?
    public var sex: String?
    public var height_cm: Double?
    public var weight_kg: Double?
    public var activity_level: String?
    public var goal: String?

    public init(age: Int? = nil, sex: String? = nil, height_cm: Double? = nil,
                weight_kg: Double? = nil, activity_level: String? = nil, goal: String? = nil) {
        self.age = age
        self.sex = sex
        self.height_cm = height_cm
        self.weight_kg = weight_kg
        self.activity_level = activity_level
        self.goal = goal
    }
}

public struct BMI: Codable {
    public let value: Double
    public let category: String
}

public struct Metric: Codable, Identifiable, Hashable {
    public let id: Int
    public let user_id: Int
    public let type: String
    public let value: Double
    public let unit: String?
    public let recorded_at: String
}

public struct MetricListResponse: Codable {
    public let metrics: [Metric]
}

public struct MetricResponse: Codable {
    public let metric: Metric
}

public struct APIError: Codable, Error, LocalizedError {
    public let error: String
    public init(error: String) { self.error = error }
    public var errorDescription: String? { error }
}

// MARK: - Nutrition

public struct Meal: Codable, Identifiable, Hashable {
    public let id: Int
    public let user_id: Int
    public let name: String
    public let kcal: Double
    public let protein_g: Double
    public let carbs_g: Double
    public let fat_g: Double
    public let barcode: String?
    public let recorded_at: String
}

public struct MealResponse: Codable {
    public let meal: Meal
}

public struct MealListResponse: Codable {
    public let meals: [Meal]
    public let totals: MealTotals
}

public struct MealTotals: Codable {
    public let kcal: Double
    public let protein_g: Double
    public let carbs_g: Double
    public let fat_g: Double
}

// MARK: - Insights

public struct ReadinessResponse: Codable {
    public let score: Int
    public let suggestion: String
    public let hrv_avg: Double?
    public let sleep_hrs: Double?
    public let workout_minutes: Double?
}

public struct WeeklyAggregate: Codable, Hashable {
    public let type: String
    public let total: Double
    public let avg: Double
    public let count: Int
    public let day: String
}

public struct WeeklyResponse: Codable {
    public let aggregates: [WeeklyAggregate]
}

// MARK: - Workout Library (local seed)

public struct WorkoutTemplate: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: WorkoutCategory
    public let level: WorkoutLevel
    public let durationMin: Int
    public let summary: String
    public let activityType: Int   // HKWorkoutActivityType raw value

    public init(id: String, name: String, category: WorkoutCategory,
                level: WorkoutLevel, durationMin: Int, summary: String,
                activityType: Int) {
        self.id = id
        self.name = name
        self.category = category
        self.level = level
        self.durationMin = durationMin
        self.summary = summary
        self.activityType = activityType
    }
}

public enum WorkoutCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, yoga, mobility
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .strength: return "Strength"
        case .cardio:   return "Cardio"
        case .yoga:     return "Yoga"
        case .mobility: return "Mobility"
        }
    }
}

public enum WorkoutLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

public enum WorkoutLibrary {
    public static let templates: [WorkoutTemplate] = [
        .init(id: "full-body-strength-30",  name: "Full-Body Strength",     category: .strength, level: .intermediate, durationMin: 30, summary: "Compound lifts: squats, presses, rows.", activityType: 50),
        .init(id: "beginner-strength-20",   name: "Beginner Strength",      category: .strength, level: .beginner,     durationMin: 20, summary: "Bodyweight + dumbbell basics.",        activityType: 50),
        .init(id: "advanced-strength-45",   name: "Advanced Power Day",     category: .strength, level: .advanced,     durationMin: 45, summary: "Heavy compounds + accessories.",       activityType: 50),
        .init(id: "hiit-cardio-15",         name: "HIIT Cardio Blast",      category: .cardio,   level: .intermediate, durationMin: 15, summary: "30s on / 30s off intervals.",          activityType: 16),
        .init(id: "easy-run-30",            name: "Easy Recovery Run",      category: .cardio,   level: .beginner,     durationMin: 30, summary: "Conversational pace, zone 2.",         activityType: 37),
        .init(id: "tempo-run-25",           name: "Tempo Run",              category: .cardio,   level: .advanced,     durationMin: 25, summary: "Sustained effort at threshold pace.",  activityType: 37),
        .init(id: "vinyasa-flow-30",        name: "Vinyasa Flow",           category: .yoga,     level: .intermediate, durationMin: 30, summary: "Breath-paced flowing sequence.",       activityType: 57),
        .init(id: "gentle-yoga-20",         name: "Gentle Morning Yoga",    category: .yoga,     level: .beginner,     durationMin: 20, summary: "Wake up your body slowly.",            activityType: 57),
        .init(id: "mobility-flow-15",       name: "Daily Mobility Flow",    category: .mobility, level: .beginner,     durationMin: 15, summary: "Hips, shoulders, T-spine.",            activityType: 53),
        .init(id: "deep-stretch-25",        name: "Deep Stretch",           category: .mobility, level: .intermediate, durationMin: 25, summary: "Long holds for full-body release.",    activityType: 53),
    ]
}
