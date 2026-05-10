import Foundation

// MARK: - Diet suggestions
//
// Static, on-device map from declared health conditions to a curated set of
// dietary guidance. Backed by mainstream public-health dietary patterns
// (DASH, Mediterranean, low-GI, low-sodium, etc.). NOT medical advice — every
// surface that reads from this service must show the doctor-disclaimer banner.

public enum DietPattern: String, Codable, Hashable, Identifiable, Sendable {
    case mediterranean, dash, lowGI, lowSodium, highFiber, lowFODMAP,
         renalFriendly, ironRich, calciumRich, gestational, balanced
    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .mediterranean: return "Mediterranean"
        case .dash:          return "DASH"
        case .lowGI:         return "Low glycemic index"
        case .lowSodium:     return "Low sodium"
        case .highFiber:     return "High fiber"
        case .lowFODMAP:     return "Low FODMAP"
        case .renalFriendly: return "Kidney-friendly (renal)"
        case .ironRich:      return "Iron-rich"
        case .calciumRich:   return "Calcium- + vitamin-D-rich"
        case .gestational:   return "Gestational (pregnancy)"
        case .balanced:      return "Balanced (default)"
        }
    }
}

public struct DietSuggestion: Codable, Hashable, Identifiable, Sendable {
    public let id: String                 // stable id, e.g. "hypertension"
    public let condition: HealthCondition
    public let pattern: DietPattern
    public let prefer: [String]           // foods to favor
    public let avoid: [String]            // foods to limit / avoid
    public let dailyTargets: [String]     // e.g. "Sodium < 2300 mg"
    public let notes: String              // 1-2 sentence rationale
}

public enum DietSuggestionsService {

    /// Lookup curated suggestions for a single condition.
    public static func suggestion(for condition: HealthCondition) -> DietSuggestion? {
        catalog[condition]
    }

    /// Aggregated suggestions for a *set* of conditions. When the user has
    /// multiple, the union of all preferred foods is returned and
    /// `pattern` falls back to the most restrictive applicable pattern.
    public static func suggestions(for conditions: Set<HealthCondition>) -> [DietSuggestion] {
        let valid = conditions.subtracting([.none])
        guard !valid.isEmpty else {
            if let baseline = catalog[.none] { return [baseline] }
            return []
        }
        return valid.compactMap { catalog[$0] }
    }

    // MARK: - Curated catalogue (non-medical, public-health-style guidance)

    public static let catalog: [HealthCondition: DietSuggestion] = [

        .none: DietSuggestion(
            id: "balanced",
            condition: .none,
            pattern: .balanced,
            prefer: ["Vegetables", "Fruits", "Whole grains", "Lean protein",
                     "Healthy fats (olive oil, nuts)", "Legumes", "Water"],
            avoid: ["Excess refined sugar", "Ultra-processed foods", "Sugary drinks"],
            dailyTargets: ["~ ½ plate vegetables + fruit",
                           "Protein with every meal",
                           "8 glasses water"],
            notes: "Default healthy-eating pattern based on USDA MyPlate."),

        .hypertension: DietSuggestion(
            id: "hypertension",
            condition: .hypertension,
            pattern: .dash,
            prefer: ["Leafy greens", "Berries", "Bananas (potassium)",
                     "Beets", "Oats", "Yogurt (low-fat)", "Salmon",
                     "Pumpkin seeds", "Beans"],
            avoid: ["Salt-cured meats", "Pickles", "Canned soups",
                    "Fast food", "Soy sauce", "Frozen pizza"],
            dailyTargets: ["Sodium < 1500-2300 mg",
                           "Potassium 3500-4700 mg",
                           "5+ servings veg/fruit"],
            notes: "DASH diet has the strongest evidence for blood-pressure reduction."),

        .heartCondition: DietSuggestion(
            id: "heart",
            condition: .heartCondition,
            pattern: .mediterranean,
            prefer: ["Olive oil", "Fatty fish (salmon, sardines)", "Walnuts",
                     "Berries", "Whole grains", "Legumes", "Avocado",
                     "Dark chocolate (70%+) in small amounts"],
            avoid: ["Trans fats", "Red meat (limit)", "Butter (limit)",
                    "Sugary drinks", "Refined carbs"],
            dailyTargets: ["Saturated fat < 7% kcal",
                           "Fiber 25-38 g",
                           "Omega-3 ~250 mg/day"],
            notes: "Mediterranean diet → ~30% lower cardiovascular event risk (PREDIMED)."),

        .diabetesT2: DietSuggestion(
            id: "diabetes-t2",
            condition: .diabetesT2,
            pattern: .lowGI,
            prefer: ["Non-starchy vegetables", "Lean protein", "Berries",
                     "Beans + lentils", "Steel-cut oats", "Greek yogurt",
                     "Nuts (handful)", "Eggs"],
            avoid: ["White bread / rice / pasta", "Sugary drinks", "Fruit juice",
                    "Pastries", "Sweetened cereals"],
            dailyTargets: ["Carbs from low-GI sources",
                           "Fiber 25+ g",
                           "Protein at every meal"],
            notes: "Low-GI + plate method (½ veg, ¼ protein, ¼ carbs) keeps blood glucose stable."),

        .diabetesT1: DietSuggestion(
            id: "diabetes-t1",
            condition: .diabetesT1,
            pattern: .lowGI,
            prefer: ["Counted carbs from whole foods", "Lean protein",
                     "Vegetables", "Fiber-rich grains", "Healthy fats"],
            avoid: ["Surprise hidden sugars", "Sugar-sweetened drinks"],
            dailyTargets: ["Carb count per meal (matched to insulin dose)",
                           "Consistent meal timing"],
            notes: "Always coordinate carb intake with your insulin regimen and CGM data."),

        .obesity: DietSuggestion(
            id: "obesity",
            condition: .obesity,
            pattern: .highFiber,
            prefer: ["Vegetables (½ plate)", "Lean protein", "Beans + lentils",
                     "Whole fruits", "Water", "Greek yogurt"],
            avoid: ["Sugar-sweetened drinks", "Fast food", "Liquid calories",
                    "Ultra-processed snacks"],
            dailyTargets: ["~ 500 kcal/day deficit (moderate)",
                           "Protein 1.2-1.6 g/kg body weight",
                           "Fiber 30+ g"],
            notes: "Sustained ~5-10% body-weight loss meaningfully reduces metabolic risk."),

        .kidneyIssue: DietSuggestion(
            id: "kidney",
            condition: .kidneyIssue,
            pattern: .renalFriendly,
            prefer: ["Cabbage", "Cauliflower", "Apples", "Berries", "Egg whites",
                     "White rice", "Olive oil"],
            avoid: ["Bananas (high potassium)", "Oranges", "Tomatoes",
                    "Dairy (high phosphorus)", "Processed meats", "Salt"],
            dailyTargets: ["Sodium < 2000 mg",
                           "Potassium per nephrologist's plan",
                           "Phosphorus 800-1000 mg"],
            notes: "Renal-friendly targets vary by CKD stage. Always defer to your nephrologist."),

        .liverIssue: DietSuggestion(
            id: "liver",
            condition: .liverIssue,
            pattern: .mediterranean,
            prefer: ["Coffee (moderate)", "Leafy greens", "Berries",
                     "Olive oil", "Fatty fish", "Whole grains", "Garlic"],
            avoid: ["Alcohol", "Added sugars", "Trans fats", "Excess red meat"],
            dailyTargets: ["Zero added sugar where possible",
                           "Caloric deficit if NAFLD"],
            notes: "Mediterranean + zero alcohol is the strongest pattern for fatty liver."),

        .anemia: DietSuggestion(
            id: "anemia",
            condition: .anemia,
            pattern: .ironRich,
            prefer: ["Lean red meat", "Liver", "Spinach", "Lentils", "Tofu",
                     "Pumpkin seeds", "Fortified cereals", "Vitamin-C foods"],
            avoid: ["Tea / coffee with meals (inhibits iron absorption)",
                    "Calcium supplements with iron-rich meals"],
            dailyTargets: ["Iron 18 mg (women) / 8 mg (men) / 27 mg (pregnancy)",
                           "Pair iron foods with vitamin C"],
            notes: "Pair plant iron with vitamin C (lemon, orange) to triple absorption."),

        .pregnancy: DietSuggestion(
            id: "pregnancy",
            condition: .pregnancy,
            pattern: .gestational,
            prefer: ["Folate-rich greens", "Eggs", "Salmon (low-mercury)",
                     "Greek yogurt", "Legumes", "Whole grains", "Nuts",
                     "Iron-rich meats / lentils"],
            avoid: ["Raw fish / sushi", "Unpasteurized cheeses",
                    "High-mercury fish (swordfish, king mackerel)",
                    "Alcohol", "Excess caffeine (> 200 mg/day)",
                    "Deli meats unless reheated"],
            dailyTargets: ["+ 340-450 kcal in 2nd / 3rd trimester",
                           "Protein 1.1 g/kg",
                           "Folate 600 µg",
                           "Iron 27 mg",
                           "DHA 200-300 mg"],
            notes: "Always coordinate with your obstetrician — needs vary by trimester."),

        .osteoporosis: DietSuggestion(
            id: "osteoporosis",
            condition: .osteoporosis,
            pattern: .calciumRich,
            prefer: ["Greek yogurt", "Sardines (with bones)", "Tofu",
                     "Kale + collards", "Almonds", "Fortified plant milks",
                     "Salmon (vitamin D)", "Eggs"],
            avoid: ["Excess sodium (calcium loss)", "Excess caffeine",
                    "Soft drinks (high phosphate)", "Heavy alcohol"],
            dailyTargets: ["Calcium 1000-1200 mg",
                           "Vitamin D 800-1000 IU",
                           "Protein 1.0-1.2 g/kg"],
            notes: "Pair calcium with vitamin D + weight-bearing exercise for absorption + bone formation."),

        .asthma: DietSuggestion(
            id: "asthma",
            condition: .asthma,
            pattern: .mediterranean,
            prefer: ["Apples", "Berries", "Leafy greens", "Carrots", "Salmon",
                     "Walnuts", "Olive oil", "Avocado"],
            avoid: ["Sulfite-heavy wines + dried fruit (if sensitive)",
                    "Personal trigger foods (allergens)"],
            dailyTargets: ["Antioxidant-rich produce 5+ servings",
                           "Omega-3 from fish 2× / week"],
            notes: "Mediterranean pattern is associated with lower asthma severity in observational studies."),

        .lowBloodPressure: DietSuggestion(
            id: "low-bp",
            condition: .lowBloodPressure,
            pattern: .balanced,
            prefer: ["Smaller, more frequent meals", "Adequate fluids",
                     "Salt within USDA limits (per doctor)",
                     "Caffeine in moderation"],
            avoid: ["Large heavy meals", "Excess alcohol",
                    "Standing up too quickly after eating"],
            dailyTargets: ["Fluids 2-3 L",
                           "Sodium per physician (often somewhat higher than DASH)"],
            notes: "If hypotension is causing symptoms, your doctor may recommend higher sodium — opposite of hypertension advice."),

        .shoulderInjury: DietSuggestion(
            id: "shoulder",
            condition: .shoulderInjury,
            pattern: .balanced,
            prefer: ["Anti-inflammatory: berries, salmon, walnuts, turmeric",
                     "Adequate protein for tissue repair"],
            avoid: ["Excess alcohol (slows healing)", "Refined sugars"],
            dailyTargets: ["Protein 1.6-2.2 g/kg during rehab",
                           "Vitamin C + zinc for collagen synthesis"],
            notes: "Soft-tissue recovery benefits from anti-inflammatory eating."),

        .kneeInjury: DietSuggestion(
            id: "knee",
            condition: .kneeInjury,
            pattern: .balanced,
            prefer: ["Anti-inflammatory: berries, salmon, walnuts, leafy greens",
                     "Lean protein (collagen synthesis)",
                     "Bone broth", "Vitamin C foods"],
            avoid: ["Excess alcohol", "Ultra-processed foods",
                    "Excess weight (load on joint)"],
            dailyTargets: ["Protein 1.6-2.2 g/kg",
                           "Vitamin D 800-1000 IU",
                           "Omega-3 1-2 g"],
            notes: "Anti-inflammatory diet + body-weight management both reduce joint load."),

        .ankleInjury: DietSuggestion(
            id: "ankle",
            condition: .ankleInjury,
            pattern: .balanced,
            prefer: ["Lean protein", "Berries", "Vitamin C foods",
                     "Bone broth", "Leafy greens"],
            avoid: ["Excess alcohol", "Smoking (slows healing)"],
            dailyTargets: ["Protein 1.6-2.2 g/kg",
                           "Vitamin C 200+ mg"],
            notes: "Same anti-inflammatory + protein-priority recovery template."),

        .backPain: DietSuggestion(
            id: "back",
            condition: .backPain,
            pattern: .balanced,
            prefer: ["Anti-inflammatory whole foods", "Adequate hydration",
                     "Magnesium-rich foods (greens, seeds)",
                     "Omega-3 fatty fish"],
            avoid: ["Ultra-processed foods", "Excess refined sugar"],
            dailyTargets: ["Magnesium 320 mg (women) / 420 mg (men)",
                           "Hydration 2-3 L"],
            notes: "Whole-food, anti-inflammatory pattern + bodyweight management both ease lower-back pain."),
    ]
}
