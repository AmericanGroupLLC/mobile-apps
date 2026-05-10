import Foundation
import Combine

// MARK: - Health conditions taxonomy
//
// Privacy-first: this is a small, opt-in list of common conditions the user
// can declare so the app filters out unsafe exercises and tunes diet/workout
// suggestions. Stored ONLY on-device in UserDefaults. Never sent to a server,
// never written to CloudKit, never logged via analytics.
//
// We deliberately keep the list short and use plain words so the user can
// understand each option. For real medical conditions, the doctor's advice
// always takes precedence over what this app shows.

public enum HealthCondition: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case none
    case hypertension          // high blood pressure
    case lowBloodPressure
    case heartCondition        // any heart history
    case diabetesT1
    case diabetesT2
    case asthma
    case pregnancy
    case kneeInjury
    case backPain
    case shoulderInjury
    case ankleInjury
    case osteoporosis
    case obesity
    case kidneyIssue
    case liverIssue
    case anemia

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .none:             return "No declared conditions"
        case .hypertension:     return "High blood pressure"
        case .lowBloodPressure: return "Low blood pressure"
        case .heartCondition:   return "Heart condition"
        case .diabetesT1:       return "Type 1 diabetes"
        case .diabetesT2:       return "Type 2 diabetes"
        case .asthma:           return "Asthma"
        case .pregnancy:        return "Pregnancy"
        case .kneeInjury:       return "Knee injury / pain"
        case .backPain:         return "Lower back pain"
        case .shoulderInjury:   return "Shoulder injury / pain"
        case .ankleInjury:      return "Ankle injury / pain"
        case .osteoporosis:     return "Osteoporosis"
        case .obesity:          return "Obesity (BMI \u{2265} 30)"
        case .kidneyIssue:      return "Kidney issue (CKD)"
        case .liverIssue:       return "Liver issue"
        case .anemia:           return "Anemia"
        }
    }

    public var symbol: String {
        switch self {
        case .none:             return "checkmark.shield"
        case .hypertension, .lowBloodPressure, .heartCondition: return "heart.text.square"
        case .diabetesT1, .diabetesT2: return "drop.degreesign"
        case .asthma:           return "lungs"
        case .pregnancy:        return "figure.and.child.holdinghands"
        case .kneeInjury, .ankleInjury: return "figure.run.circle"
        case .backPain:         return "figure.walk.motion"
        case .shoulderInjury:   return "figure.arms.open"
        case .osteoporosis:     return "figure.stairs"
        case .obesity:          return "scalemass"
        case .kidneyIssue, .liverIssue: return "cross.case"
        case .anemia:           return "drop"
        }
    }
}

// MARK: - Persistent store

@MainActor
public final class HealthConditionsStore: ObservableObject {

    public static let shared = HealthConditionsStore()
    public static let storageKey = "healthConditions.v1"

    @Published public var conditions: Set<HealthCondition> {
        didSet { persist() }
    }

    /// Last time the user said \u{201C}I checked with a doctor about these
    /// conditions\u{201D}. Used to remind them after 6 months.
    @Published public var lastDoctorReview: Date? {
        didSet {
            UserDefaults.standard.set(lastDoctorReview,
                                      forKey: "healthConditions.lastDoctorReview")
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(Set<HealthCondition>.self, from: data) {
            self.conditions = decoded
        } else {
            self.conditions = [.none]
        }
        self.lastDoctorReview = UserDefaults.standard.object(
            forKey: "healthConditions.lastDoctorReview") as? Date
    }

    public func toggle(_ c: HealthCondition) {
        if c == .none {
            conditions = [.none]
            return
        }
        if conditions.contains(c) {
            conditions.remove(c)
        } else {
            conditions.insert(c)
            conditions.remove(.none)
        }
        if conditions.isEmpty { conditions = [.none] }
    }

    public var hasAnyCondition: Bool {
        !conditions.isEmpty && conditions != [.none]
    }

    public var doctorReviewIsStale: Bool {
        guard let last = lastDoctorReview else { return hasAnyCondition }
        return Date().timeIntervalSince(last) > 60 * 60 * 24 * 30 * 6 // 6 months
    }

    public func markReviewedWithDoctor() {
        lastDoctorReview = Date()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(conditions) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
