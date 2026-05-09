import Foundation
import CoreData
import CloudKit
import Combine

/// Wraps NSPersistentCloudKitContainer to sync user-generated WorkoutPlanEntity,
/// MealEntity, and MoodEntryEntity between iPhone <-> Apple Watch via the user's iCloud.
/// This is orthogonal to the Express backend, which remains source of truth for cross-platform data.
@MainActor
public final class CloudStore: ObservableObject {
    public static let shared = CloudStore()

    public let container: NSPersistentCloudKitContainer

    @Published public private(set) var lastError: String?

    private init() {
        let modelURL = Bundle.module.url(forResource: "FitFusionModel", withExtension: "momd")
        let model = modelURL.flatMap { NSManagedObjectModel(contentsOf: $0) } ?? NSManagedObjectModel()

        container = NSPersistentCloudKitContainer(name: "FitFusionModel", managedObjectModel: model)

        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.fitfusion")
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                Task { @MainActor in self?.lastError = error.localizedDescription }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public var viewContext: NSManagedObjectContext { container.viewContext }

    public func save() {
        let ctx = viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Workout Plans

    @discardableResult
    public func addWorkoutPlan(templateId: String, scheduledFor: Date, notes: String? = nil) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "WorkoutPlanEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(templateId, forKey: "templateId")
        entity.setValue(scheduledFor, forKey: "scheduledFor")
        entity.setValue(notes, forKey: "notes")
        entity.setValue(Date(), forKey: "createdAt")
        save()
        return entity
    }

    public func fetchTodayPlans() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "WorkoutPlanEntity")
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        req.predicate = NSPredicate(format: "scheduledFor >= %@ AND scheduledFor < %@",
                                    start as NSDate, end as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "scheduledFor", ascending: true)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Meals

    @discardableResult
    public func addMeal(name: String, kcal: Double, protein: Double,
                        carbs: Double, fat: Double, barcode: String? = nil) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "MealEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(name, forKey: "name")
        entity.setValue(kcal, forKey: "kcal")
        entity.setValue(protein, forKey: "protein")
        entity.setValue(carbs, forKey: "carbs")
        entity.setValue(fat, forKey: "fat")
        entity.setValue(barcode, forKey: "barcode")
        entity.setValue(Date(), forKey: "consumedAt")
        save()
        return entity
    }

    public func fetchTodayMeals() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "MealEntity")
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        req.predicate = NSPredicate(format: "consumedAt >= %@ AND consumedAt < %@",
                                    start as NSDate, end as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "consumedAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Mood Entries

    @discardableResult
    public func addMoodEntry(value: Int, note: String? = nil) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "MoodEntryEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(Int16(value), forKey: "value")
        entity.setValue(note, forKey: "note")
        entity.setValue(Date(), forKey: "recordedAt")
        save()
        return entity
    }

    // MARK: - State of Mind (mirrors HKStateOfMindSample on iOS 17+)

    @discardableResult
    public func addStateOfMind(label: String,
                               valence: Double,
                               arousal: Double = 0,
                               context: String? = nil) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "StateOfMindEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(label, forKey: "label")
        entity.setValue(valence, forKey: "valence")
        entity.setValue(arousal, forKey: "arousal")
        entity.setValue(context, forKey: "context")
        entity.setValue(Date(), forKey: "recordedAt")
        save()
        return entity
    }

    public func fetchRecentStateOfMind(daysBack: Int = 7) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "StateOfMindEntity")
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -daysBack, to: Date()) else { return [] }
        req.predicate = NSPredicate(format: "recordedAt >= %@", start as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Friends (Layer 5)

    @discardableResult
    public func addFriend(name: String, handle: String, recordID: String? = nil) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "FriendEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(name, forKey: "name")
        entity.setValue(handle, forKey: "handle")
        entity.setValue(recordID, forKey: "recordID")
        entity.setValue(Date(), forKey: "addedAt")
        save()
        return entity
    }

    public func fetchFriends() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "FriendEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Challenges (Layer 5)

    @discardableResult
    public func addChallenge(title: String, kind: String,
                             startsAt: Date, endsAt: Date,
                             target: Double) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ChallengeEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(title, forKey: "title")
        entity.setValue(kind, forKey: "kind")
        entity.setValue(startsAt, forKey: "startsAt")
        entity.setValue(endsAt, forKey: "endsAt")
        entity.setValue(target, forKey: "target")
        entity.setValue(Date(), forKey: "joinedAt")
        save()
        return entity
    }

    public func fetchActiveChallenges() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "ChallengeEntity")
        req.predicate = NSPredicate(format: "endsAt >= %@", Date() as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "endsAt", ascending: true)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Badges (Layer 5)

    @discardableResult
    public func awardBadge(slug: String, title: String, subtitle: String) -> NSManagedObject? {
        // Idempotent: if a badge with this slug already exists, return it instead.
        let req = NSFetchRequest<NSManagedObject>(entityName: "BadgeEntity")
        req.predicate = NSPredicate(format: "slug == %@", slug)
        if let existing = (try? viewContext.fetch(req))?.first { return existing }

        let entity = NSEntityDescription.insertNewObject(forEntityName: "BadgeEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(slug, forKey: "slug")
        entity.setValue(title, forKey: "title")
        entity.setValue(subtitle, forKey: "subtitle")
        entity.setValue(Date(), forKey: "awardedAt")
        save()
        return entity
    }

    public func fetchBadges() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "BadgeEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "awardedAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Streaks (Layer 5)

    @discardableResult
    public func upsertStreak(kind: String, currentDays: Int, longestDays: Int, lastDay: Date) -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "StreakEntity")
        req.predicate = NSPredicate(format: "kind == %@", kind)
        let entity = (try? viewContext.fetch(req))?.first
            ?? NSEntityDescription.insertNewObject(forEntityName: "StreakEntity", into: viewContext)
        entity.setValue(entity.value(forKey: "id") ?? UUID(), forKey: "id")
        entity.setValue(kind, forKey: "kind")
        entity.setValue(Int32(currentDays), forKey: "currentDays")
        entity.setValue(Int32(longestDays), forKey: "longestDays")
        entity.setValue(lastDay, forKey: "lastDay")
        save()
        return entity
    }

    public func fetchStreaks() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "StreakEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "currentDays", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Exercise logs (workout logger)

    /// One exercise performance \u{2014} e.g. "Bench Press: 5\u{00d7}5 @ 60kg" \u{2014} persisted as a
    /// JSON-encoded array of (reps, weight) sets so we don't need a child entity.
    public struct LoggedSet: Codable, Hashable {
        public var reps: Int
        public var weight: Double      // kg (or lb \u{2014} caller decides per-app)
        public init(reps: Int, weight: Double) {
            self.reps = reps; self.weight = weight
        }
    }

    @discardableResult
    public func addExerciseLog(exerciseId: String,
                               sets: [LoggedSet],
                               notes: String? = nil,
                               performedAt: Date = Date()) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ExerciseLogEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(exerciseId, forKey: "exerciseId")
        entity.setValue(performedAt, forKey: "performedAt")
        if let json = try? JSONEncoder().encode(sets),
           let str = String(data: json, encoding: .utf8) {
            entity.setValue(str, forKey: "setsJSON")
        }
        entity.setValue(notes, forKey: "notes")
        save()
        return entity
    }

    public func fetchExerciseLogs(exerciseId: String? = nil, limit: Int = 100) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "ExerciseLogEntity")
        if let exerciseId = exerciseId {
            req.predicate = NSPredicate(format: "exerciseId == %@", exerciseId)
        }
        req.sortDescriptors = [NSSortDescriptor(key: "performedAt", ascending: false)]
        req.fetchLimit = limit
        return (try? viewContext.fetch(req)) ?? []
    }

    /// Decode the stored sets blob.
    public static func decodeSets(_ obj: NSManagedObject) -> [LoggedSet] {
        guard let json = obj.value(forKey: "setsJSON") as? String,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([LoggedSet].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Heaviest single rep across all logs for an exercise (a simple PR proxy).
    public func personalRecord(for exerciseId: String) -> Double? {
        let logs = fetchExerciseLogs(exerciseId: exerciseId)
        let weights = logs.flatMap { Self.decodeSets($0).map(\.weight) }
        return weights.max()
    }

    // MARK: - Custom workouts

    @discardableResult
    public func addCustomWorkout(name: String, exerciseIds: [String]) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "CustomWorkoutEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(name, forKey: "name")
        if let data = try? JSONEncoder().encode(exerciseIds),
           let str = String(data: data, encoding: .utf8) {
            entity.setValue(str, forKey: "exerciseIdsJSON")
        }
        entity.setValue(Date(), forKey: "createdAt")
        save()
        return entity
    }

    public func fetchCustomWorkouts() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CustomWorkoutEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    public static func decodeExerciseIds(_ obj: NSManagedObject) -> [String] {
        guard let json = obj.value(forKey: "exerciseIdsJSON") as? String,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Profile (no-account, local-first user record)

    @discardableResult
    public func saveProfile(name: String,
                            birthDateISO: String,
                            sex: String,
                            heightCm: Double,
                            weightKg: Double,
                            goal: String,
                            activityLevel: String? = nil,
                            unitsImperial: Bool = false,
                            themeMode: String? = nil,
                            language: String? = nil) -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "ProfileEntity")
        req.fetchLimit = 1
        let entity = (try? viewContext.fetch(req))?.first
            ?? NSEntityDescription.insertNewObject(forEntityName: "ProfileEntity", into: viewContext)
        entity.setValue(entity.value(forKey: "id") ?? UUID(), forKey: "id")
        entity.setValue(name, forKey: "name")
        entity.setValue(birthDateISO, forKey: "birthDateISO")
        entity.setValue(sex, forKey: "sex")
        entity.setValue(heightCm, forKey: "heightCm")
        entity.setValue(weightKg, forKey: "weightKg")
        entity.setValue(goal, forKey: "goal")
        if let activityLevel { entity.setValue(activityLevel, forKey: "activityLevel") }
        entity.setValue(unitsImperial, forKey: "unitsImperial")
        if let themeMode { entity.setValue(themeMode, forKey: "themeMode") }
        if let language { entity.setValue(language, forKey: "language") }
        entity.setValue(Date(), forKey: "updatedAt")
        save()
        return entity
    }

    public func fetchProfile() -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "ProfileEntity")
        req.fetchLimit = 1
        return (try? viewContext.fetch(req))?.first
    }

    // MARK: - Medicine

    @discardableResult
    public func addMedicine(name: String,
                            dosage: String,
                            unit: String,
                            manufacturer: String? = nil,
                            priceCents: Int = 0,
                            criticalLevel: String = "low",
                            eatWhen: String = "standalone",
                            scheduleJSON: String,
                            colorHex: String = "#5B8DEF",
                            notes: String? = nil) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "MedicineEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(name, forKey: "name")
        entity.setValue(dosage, forKey: "dosage")
        entity.setValue(unit, forKey: "unit")
        entity.setValue(manufacturer, forKey: "manufacturer")
        entity.setValue(Int32(priceCents), forKey: "priceCents")
        entity.setValue(criticalLevel, forKey: "criticalLevel")
        entity.setValue(eatWhen, forKey: "eatWhen")
        entity.setValue(scheduleJSON, forKey: "scheduleJSON")
        entity.setValue(colorHex, forKey: "colorHex")
        entity.setValue(notes, forKey: "notes")
        entity.setValue(Date(), forKey: "createdAt")
        save()
        return entity
    }

    public func fetchMedicines(includeArchived: Bool = false) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "MedicineEntity")
        if !includeArchived {
            req.predicate = NSPredicate(format: "archivedAt == nil")
        }
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    public func archiveMedicine(_ obj: NSManagedObject) {
        obj.setValue(Date(), forKey: "archivedAt")
        save()
    }

    @discardableResult
    public func logDose(medicineId: UUID,
                        scheduledFor: Date,
                        takenAt: Date? = nil,
                        snoozedAt: Date? = nil,
                        skipped: Bool = false) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "MedicineDoseLogEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(medicineId, forKey: "medicineId")
        entity.setValue(scheduledFor, forKey: "scheduledFor")
        entity.setValue(takenAt, forKey: "takenAt")
        entity.setValue(snoozedAt, forKey: "snoozedAt")
        entity.setValue(skipped, forKey: "skipped")
        save()
        return entity
    }

    public func recentDoseLogs(for medicineId: UUID, limit: Int = 30) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "MedicineDoseLogEntity")
        req.predicate = NSPredicate(format: "medicineId == %@", medicineId as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "scheduledFor", ascending: false)]
        req.fetchLimit = limit
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Activities

    @discardableResult
    public func addActivity(kind: String,
                            durationMin: Double,
                            kcalBurned: Double = 0,
                            notes: String? = nil,
                            performedAt: Date = Date()) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ActivityEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(kind, forKey: "kind")
        entity.setValue(durationMin, forKey: "durationMin")
        entity.setValue(kcalBurned, forKey: "kcalBurned")
        entity.setValue(notes, forKey: "notes")
        entity.setValue(performedAt, forKey: "performedAt")
        save()
        return entity
    }

    public func fetchActivities(daysBack: Int = 30) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "ActivityEntity")
        if let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) {
            req.predicate = NSPredicate(format: "performedAt >= %@", start as NSDate)
        }
        req.sortDescriptors = [NSSortDescriptor(key: "performedAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    // MARK: - Custom meals

    public struct MealComponent: Codable, Hashable {
        public var foodId: String
        public var name: String
        public var grams: Double
        public init(foodId: String, name: String, grams: Double) {
            self.foodId = foodId; self.name = name; self.grams = grams
        }
    }

    @discardableResult
    public func addCustomMeal(name: String, components: [MealComponent]) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "CustomMealEntity", into: viewContext)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(name, forKey: "name")
        if let data = try? JSONEncoder().encode(components),
           let str = String(data: data, encoding: .utf8) {
            entity.setValue(str, forKey: "componentsJSON")
        }
        entity.setValue(Date(), forKey: "createdAt")
        save()
        return entity
    }

    public func fetchCustomMeals() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CustomMealEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }

    public static func decodeMealComponents(_ obj: NSManagedObject) -> [MealComponent] {
        guard let json = obj.value(forKey: "componentsJSON") as? String,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([MealComponent].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Convenience: meals across the past N days (for Diary)

    public func fetchMeals(daysBack: Int) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "MealEntity")
        if let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) {
            req.predicate = NSPredicate(format: "consumedAt >= %@", start as NSDate)
        }
        req.sortDescriptors = [NSSortDescriptor(key: "consumedAt", ascending: false)]
        return (try? viewContext.fetch(req)) ?? []
    }
}
