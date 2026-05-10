import Foundation
import FitFusionCore
import CoreData

/// Cross-platform JSON export/import. Writes a single `myhealth-backup-...
/// .json` file containing every on-device entity, conforming to the schema
/// at `shared/schemas/myhealth.schema.json`.
@MainActor
public final class PortabilityService {
    public static let shared = PortabilityService()
    private init() {}

    private let dateFormatter = ISO8601DateFormatter()

    public struct Backup: Codable {
        public var schemaVersion: Int = 1
        public var exportedAt: String
        public var profile: ProfilePayload?
        public var meals: [MealPayload]
        public var activities: [ActivityPayload]
        public var medicines: [MedicinePayload]
        public var doseLogs: [DoseLogPayload]
        public var moodEntries: [MoodPayload]
        public var stateOfMind: [StateOfMindPayload]
        public var workoutPlans: [WorkoutPlanPayload]
        public var exerciseLogs: [ExerciseLogPayload]
        public var customWorkouts: [CustomWorkoutPayload]
        public var customMeals: [CustomMealPayload]
        public var friends: [FriendPayload]
        public var challenges: [ChallengePayload]
        public var badges: [BadgePayload]
        public var streaks: [StreakPayload]
    }

    public struct ProfilePayload: Codable {
        public var id: String
        public var name: String?
        public var birthDateISO: String?
        public var sex: String?
        public var heightCm: Double?
        public var weightKg: Double?
        public var goal: String?
        public var activityLevel: String?
        public var unitsImperial: Bool?
        public var themeMode: String?
        public var language: String?
        public var updatedAt: String?
    }
    public struct MealPayload: Codable {
        public var id: String; public var name: String?
        public var kcal: Double; public var protein: Double; public var carbs: Double; public var fat: Double
        public var barcode: String?; public var consumedAt: String?
    }
    public struct ActivityPayload: Codable {
        public var id: String; public var kind: String?
        public var durationMin: Double; public var kcalBurned: Double
        public var notes: String?; public var performedAt: String?
    }
    public struct MedicinePayload: Codable {
        public var id: String; public var name: String?; public var dosage: String?
        public var unit: String?; public var manufacturer: String?
        public var priceCents: Int?; public var criticalLevel: String?
        public var eatWhen: String?; public var scheduleJSON: String?
        public var colorHex: String?; public var notes: String?
        public var createdAt: String?; public var archivedAt: String?
    }
    public struct DoseLogPayload: Codable {
        public var id: String; public var medicineId: String?
        public var scheduledFor: String?; public var takenAt: String?; public var snoozedAt: String?
        public var skipped: Bool?
    }
    public struct MoodPayload: Codable {
        public var id: String; public var value: Int; public var note: String?; public var recordedAt: String?
    }
    public struct StateOfMindPayload: Codable {
        public var id: String; public var label: String?; public var valence: Double; public var arousal: Double
        public var context: String?; public var recordedAt: String?
    }
    public struct WorkoutPlanPayload: Codable {
        public var id: String; public var templateId: String?; public var scheduledFor: String?
        public var notes: String?; public var createdAt: String?
    }
    public struct ExerciseLogPayload: Codable {
        public var id: String; public var exerciseId: String?
        public var performedAt: String?; public var setsJSON: String?; public var notes: String?
    }
    public struct CustomWorkoutPayload: Codable {
        public var id: String; public var name: String?
        public var exerciseIdsJSON: String?; public var createdAt: String?
    }
    public struct CustomMealPayload: Codable {
        public var id: String; public var name: String?
        public var componentsJSON: String?; public var createdAt: String?
    }
    public struct FriendPayload: Codable {
        public var id: String; public var name: String?; public var handle: String?
        public var recordID: String?; public var addedAt: String?
    }
    public struct ChallengePayload: Codable {
        public var id: String; public var title: String?; public var kind: String?
        public var startsAt: String?; public var endsAt: String?
        public var target: Double?; public var joinedAt: String?
    }
    public struct BadgePayload: Codable {
        public var id: String; public var slug: String?; public var title: String?
        public var subtitle: String?; public var awardedAt: String?
    }
    public struct StreakPayload: Codable {
        public var id: String; public var kind: String?
        public var currentDays: Int; public var longestDays: Int; public var lastDay: String?
    }

    // MARK: - Export

    public func exportEverything() throws -> URL {
        let backup = Backup(
            schemaVersion: 1,
            exportedAt: dateFormatter.string(from: Date()),
            profile: exportProfile(),
            meals: exportMeals(),
            activities: exportActivities(),
            medicines: exportMedicines(),
            doseLogs: exportDoseLogs(),
            moodEntries: exportMoods(),
            stateOfMind: exportStateOfMind(),
            workoutPlans: exportWorkoutPlans(),
            exerciseLogs: exportExerciseLogs(),
            customWorkouts: exportCustomWorkouts(),
            customMeals: exportCustomMeals(),
            friends: exportFriends(),
            challenges: exportChallenges(),
            badges: exportBadges(),
            streaks: exportStreaks()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)

        let dir = FileManager.default.temporaryDirectory
        let fname = "myhealth-backup-\(yyyymmdd()).json"
        let url = dir.appendingPathComponent(fname)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Erase

    public func eraseAllLocalData() {
        let entityNames = [
            "ProfileEntity", "MealEntity", "ActivityEntity", "MedicineEntity",
            "MedicineDoseLogEntity", "MoodEntryEntity", "StateOfMindEntity",
            "WorkoutPlanEntity", "ExerciseLogEntity", "CustomWorkoutEntity",
            "CustomMealEntity", "FriendEntity", "ChallengeEntity",
            "BadgeEntity", "StreakEntity",
        ]
        let ctx = CloudStore.shared.viewContext
        for name in entityNames {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? CloudStore.shared.container.persistentStoreCoordinator
                .execute(delete, with: ctx)
        }
        ctx.reset()
        UserDefaults.standard.removeObject(forKey: AuthStore.didOnboardKey)
    }

    // MARK: - Per-entity exporters

    private func exportProfile() -> ProfilePayload? {
        guard let p = CloudStore.shared.fetchProfile() else { return nil }
        return ProfilePayload(
            id: ((p.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
            name: p.value(forKey: "name") as? String,
            birthDateISO: p.value(forKey: "birthDateISO") as? String,
            sex: p.value(forKey: "sex") as? String,
            heightCm: p.value(forKey: "heightCm") as? Double,
            weightKg: p.value(forKey: "weightKg") as? Double,
            goal: p.value(forKey: "goal") as? String,
            activityLevel: p.value(forKey: "activityLevel") as? String,
            unitsImperial: p.value(forKey: "unitsImperial") as? Bool,
            themeMode: p.value(forKey: "themeMode") as? String,
            language: p.value(forKey: "language") as? String,
            updatedAt: dateFormatter.string(from: (p.value(forKey: "updatedAt") as? Date) ?? Date())
        )
    }

    private func exportMeals() -> [MealPayload] {
        CloudStore.shared.fetchMeals(daysBack: 365 * 5).map { m in
            MealPayload(
                id: ((m.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                name: m.value(forKey: "name") as? String,
                kcal: (m.value(forKey: "kcal") as? Double) ?? 0,
                protein: (m.value(forKey: "protein") as? Double) ?? 0,
                carbs: (m.value(forKey: "carbs") as? Double) ?? 0,
                fat: (m.value(forKey: "fat") as? Double) ?? 0,
                barcode: m.value(forKey: "barcode") as? String,
                consumedAt: (m.value(forKey: "consumedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportActivities() -> [ActivityPayload] {
        CloudStore.shared.fetchActivities(daysBack: 365 * 5).map { a in
            ActivityPayload(
                id: ((a.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                kind: a.value(forKey: "kind") as? String,
                durationMin: (a.value(forKey: "durationMin") as? Double) ?? 0,
                kcalBurned: (a.value(forKey: "kcalBurned") as? Double) ?? 0,
                notes: a.value(forKey: "notes") as? String,
                performedAt: (a.value(forKey: "performedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportMedicines() -> [MedicinePayload] {
        CloudStore.shared.fetchMedicines(includeArchived: true).map { m in
            MedicinePayload(
                id: ((m.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                name: m.value(forKey: "name") as? String,
                dosage: m.value(forKey: "dosage") as? String,
                unit: m.value(forKey: "unit") as? String,
                manufacturer: m.value(forKey: "manufacturer") as? String,
                priceCents: (m.value(forKey: "priceCents") as? Int32).map { Int($0) },
                criticalLevel: m.value(forKey: "criticalLevel") as? String,
                eatWhen: m.value(forKey: "eatWhen") as? String,
                scheduleJSON: m.value(forKey: "scheduleJSON") as? String,
                colorHex: m.value(forKey: "colorHex") as? String,
                notes: m.value(forKey: "notes") as? String,
                createdAt: (m.value(forKey: "createdAt") as? Date).map(dateFormatter.string),
                archivedAt: (m.value(forKey: "archivedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportDoseLogs() -> [DoseLogPayload] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "MedicineDoseLogEntity")
        let logs = (try? CloudStore.shared.viewContext.fetch(req)) ?? []
        return logs.map { d in
            DoseLogPayload(
                id: ((d.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                medicineId: (d.value(forKey: "medicineId") as? UUID)?.uuidString,
                scheduledFor: (d.value(forKey: "scheduledFor") as? Date).map(dateFormatter.string),
                takenAt: (d.value(forKey: "takenAt") as? Date).map(dateFormatter.string),
                snoozedAt: (d.value(forKey: "snoozedAt") as? Date).map(dateFormatter.string),
                skipped: d.value(forKey: "skipped") as? Bool
            )
        }
    }
    private func exportMoods() -> [MoodPayload] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "MoodEntryEntity")
        return ((try? CloudStore.shared.viewContext.fetch(req)) ?? []).map { e in
            MoodPayload(
                id: ((e.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                value: Int((e.value(forKey: "value") as? Int16) ?? 3),
                note: e.value(forKey: "note") as? String,
                recordedAt: (e.value(forKey: "recordedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportStateOfMind() -> [StateOfMindPayload] {
        CloudStore.shared.fetchRecentStateOfMind(daysBack: 365 * 5).map { s in
            StateOfMindPayload(
                id: ((s.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                label: s.value(forKey: "label") as? String,
                valence: (s.value(forKey: "valence") as? Double) ?? 0,
                arousal: (s.value(forKey: "arousal") as? Double) ?? 0,
                context: s.value(forKey: "context") as? String,
                recordedAt: (s.value(forKey: "recordedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportWorkoutPlans() -> [WorkoutPlanPayload] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "WorkoutPlanEntity")
        return ((try? CloudStore.shared.viewContext.fetch(req)) ?? []).map { p in
            WorkoutPlanPayload(
                id: ((p.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                templateId: p.value(forKey: "templateId") as? String,
                scheduledFor: (p.value(forKey: "scheduledFor") as? Date).map(dateFormatter.string),
                notes: p.value(forKey: "notes") as? String,
                createdAt: (p.value(forKey: "createdAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportExerciseLogs() -> [ExerciseLogPayload] {
        CloudStore.shared.fetchExerciseLogs(limit: 10000).map { l in
            ExerciseLogPayload(
                id: ((l.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                exerciseId: l.value(forKey: "exerciseId") as? String,
                performedAt: (l.value(forKey: "performedAt") as? Date).map(dateFormatter.string),
                setsJSON: l.value(forKey: "setsJSON") as? String,
                notes: l.value(forKey: "notes") as? String
            )
        }
    }
    private func exportCustomWorkouts() -> [CustomWorkoutPayload] {
        CloudStore.shared.fetchCustomWorkouts().map { w in
            CustomWorkoutPayload(
                id: ((w.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                name: w.value(forKey: "name") as? String,
                exerciseIdsJSON: w.value(forKey: "exerciseIdsJSON") as? String,
                createdAt: (w.value(forKey: "createdAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportCustomMeals() -> [CustomMealPayload] {
        CloudStore.shared.fetchCustomMeals().map { m in
            CustomMealPayload(
                id: ((m.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                name: m.value(forKey: "name") as? String,
                componentsJSON: m.value(forKey: "componentsJSON") as? String,
                createdAt: (m.value(forKey: "createdAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportFriends() -> [FriendPayload] {
        CloudStore.shared.fetchFriends().map { f in
            FriendPayload(
                id: ((f.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                name: f.value(forKey: "name") as? String,
                handle: f.value(forKey: "handle") as? String,
                recordID: f.value(forKey: "recordID") as? String,
                addedAt: (f.value(forKey: "addedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportChallenges() -> [ChallengePayload] {
        CloudStore.shared.fetchActiveChallenges().map { c in
            ChallengePayload(
                id: ((c.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                title: c.value(forKey: "title") as? String,
                kind: c.value(forKey: "kind") as? String,
                startsAt: (c.value(forKey: "startsAt") as? Date).map(dateFormatter.string),
                endsAt: (c.value(forKey: "endsAt") as? Date).map(dateFormatter.string),
                target: c.value(forKey: "target") as? Double,
                joinedAt: (c.value(forKey: "joinedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportBadges() -> [BadgePayload] {
        CloudStore.shared.fetchBadges().map { b in
            BadgePayload(
                id: ((b.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                slug: b.value(forKey: "slug") as? String,
                title: b.value(forKey: "title") as? String,
                subtitle: b.value(forKey: "subtitle") as? String,
                awardedAt: (b.value(forKey: "awardedAt") as? Date).map(dateFormatter.string)
            )
        }
    }
    private func exportStreaks() -> [StreakPayload] {
        CloudStore.shared.fetchStreaks().map { s in
            StreakPayload(
                id: ((s.value(forKey: "id") as? UUID)?.uuidString) ?? UUID().uuidString,
                kind: s.value(forKey: "kind") as? String,
                currentDays: Int((s.value(forKey: "currentDays") as? Int32) ?? 0),
                longestDays: Int((s.value(forKey: "longestDays") as? Int32) ?? 0),
                lastDay: (s.value(forKey: "lastDay") as? Date).map(dateFormatter.string)
            )
        }
    }

    private func yyyymmdd() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
