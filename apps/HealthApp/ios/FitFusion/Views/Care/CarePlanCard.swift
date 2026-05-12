import SwiftUI
import FitFusionCore

/// Per-condition care plan card. Mirrors the design-spec mockup:
///  • Title + symbol on the left
///  • Latest reading pill on the right (color-coded)
///  • Goal line beneath
///  • Intervention tags as small pills at the bottom
///
/// Reading values come from a `CarePlanRecipe` map (see below) which
/// week-1 builds against the on-device `HealthConditionsStore`. Real
/// values are populated by the new `CarePlanReadings` helper, which in
/// week-2 will read HealthKit (BP, glucose, HRV) directly. For now
/// readings are placeholders unless the caller hands in a value.
public struct CarePlanCard: View {
    public let condition: HealthCondition
    public let reading: String?
    public let readingHealthy: Bool

    private let tint = CarePlusPalette.careBlue

    public init(condition: HealthCondition, reading: String? = nil, readingHealthy: Bool = true) {
        self.condition = condition
        self.reading = reading
        self.readingHealthy = readingHealthy
    }

    public var body: some View {
        let recipe = CarePlanRecipe.recipe(for: condition)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: condition.symbol).foregroundStyle(tint)
                    Text(recipe.title).font(.headline)
                }
                Spacer()
                if let r = reading {
                    Text(r).font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(
                            (readingHealthy ? CarePlusPalette.success
                                            : CarePlusPalette.warning).opacity(0.18),
                            in: Capsule()
                        )
                        .foregroundStyle(readingHealthy ? CarePlusPalette.success
                                                         : CarePlusPalette.warning)
                }
            }
            Text(recipe.goal).font(.caption).foregroundStyle(.secondary)
            if !recipe.interventions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recipe.interventions, id: \.self) { tag in
                            Text(tag).font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(tint.opacity(0.10), in: Capsule())
                                .foregroundStyle(tint)
                        }
                    }
                }
            }
        }
        .padding(CarePlusSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarePlusPalette.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }
}

/// Per-condition copy: human-readable title, goal sentence, list of
/// intervention tags. Stored here so a designer can iterate on the
/// language without touching the rendering view.
public enum CarePlanRecipe {
    public struct Recipe {
        public let title: String
        public let goal: String
        public let interventions: [String]
    }

    public static func recipe(for c: HealthCondition) -> Recipe {
        switch c {
        case .hypertension:
            return Recipe(title: "Hypertension",
                          goal: "Goal: under 130/80",
                          interventions: ["Low sodium", "BP log", "DASH plan"])
        case .lowBloodPressure:
            return Recipe(title: "Low blood pressure",
                          goal: "Stay hydrated; avoid sudden standing",
                          interventions: ["Hydration", "Salt"])
        case .heartCondition:
            return Recipe(title: "Heart condition",
                          goal: "Stay under prescribed HR cap",
                          interventions: ["HR cap", "Rest day"])
        case .diabetesT1:
            return Recipe(title: "Type 1 diabetes",
                          goal: "Pre/post-meal glucose check",
                          interventions: ["Carb count", "Insulin log"])
        case .diabetesT2:
            return Recipe(title: "Type 2 diabetes / Prediabetes",
                          goal: "Goal: A1C under 5.7 by next labs",
                          interventions: ["Diet", "Exercise", "Lab retest"])
        case .obesity:
            return Recipe(title: "Weight management",
                          goal: "Steady cardio + 0.5 kg/week deficit",
                          interventions: ["DASH", "Walk 10k"])
        case .asthma:
            return Recipe(title: "Asthma",
                          goal: "Carry inhaler; watch AQI",
                          interventions: ["AQI alert", "Inhaler log"])
        case .pregnancy:
            return Recipe(title: "Pregnancy",
                          goal: "Folate, iron, low-impact cardio",
                          interventions: ["Folate", "Walk", "Yoga"])
        case .kneeInjury, .ankleInjury, .shoulderInjury, .backPain, .osteoporosis:
            return Recipe(title: c.label,
                          goal: "Avoid high-impact; mobility work daily",
                          interventions: ["Mobility", "Ice/heat"])
        case .kidneyIssue:
            return Recipe(title: "Kidney (CKD)",
                          goal: "Low-K and low-P meals",
                          interventions: ["Low K", "Low P"])
        case .liverIssue:
            return Recipe(title: "Liver",
                          goal: "Low alcohol, watch acetaminophen",
                          interventions: ["No alcohol"])
        case .anemia:
            return Recipe(title: "Anemia",
                          goal: "Iron + vitamin-C pairings",
                          interventions: ["Iron", "Vit C"])
        case .none:
            return Recipe(title: "No conditions declared",
                          goal: "Stay active, sleep well, eat well.",
                          interventions: [])
        }
    }
}

/// Helper that returns a (reading, healthy) tuple per condition. Week 1
/// returns nil unless we have a hardcoded demo value; week 2 wires
/// HealthKit (`HKHealthStore`) for BP, glucose, HRV.
public enum CarePlanReadings {
    public static func reading(for condition: HealthCondition) -> (String, Bool)? {
        switch condition {
        case .hypertension:     return ("138/88", false) // mocked; HK in week 2
        case .diabetesT1, .diabetesT2: return ("A1C 6.1", false)
        case .heartCondition:   return ("HR 72", true)
        case .obesity:          return ("BMI 31", false)
        default: return nil
        }
    }
}
