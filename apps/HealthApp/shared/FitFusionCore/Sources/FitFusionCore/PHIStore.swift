import Foundation
#if canImport(CoreData)
import CoreData

/// Secondary persistent store for PHI-bearing entities (InsuranceCardEntity,
/// ProviderEntity, RPELogEntity, future MyChart-derived rows).
///
/// Lives in a separate `NSPersistentStoreDescription` from the main
/// FitFusion model so we can:
/// 1. Set `NSPersistentStoreFileProtectionKey = .complete` — data is
///    unavailable while the device is locked (HIPAA at-rest requirement).
/// 2. Disable CloudKit sync (PHI must not leave the device until a BAA
///    with iCloud is in place).
/// 3. Wipe just PHI on logout without touching the user's fitness history.
///
/// Schema for week 1 — three entities, kept here as in-code definitions so
/// the model is self-contained and doesn't require an .xcdatamodeld split:
///
///   PHIInsuranceCardEntity:
///     id (UUID), payer (String?), memberId (String?), groupNumber (String?),
///     bin (String?), pcn (String?), rxGrp (String?), capturedAt (Date)
///
///   PHIProviderEntity:
///     id (UUID), npi (String), name (String), specialty (String?),
///     phone (String?), addressLine (String?), zip (String?),
///     favoritedAt (Date)
///
///   PHIRPELogEntity:
///     id (UUID), workoutSessionId (String?), rating (Int16),
///     loggedAt (Date), notes (String?)
@MainActor
public final class PHIStore {

    public static let shared = PHIStore()

    public private(set) var container: NSPersistentContainer

    private init() {
        let model = Self.buildModel()
        container = NSPersistentContainer(name: "FitFusionPHI", managedObjectModel: model)

        let storeURL = Self.defaultStoreURL()
        let description = NSPersistentStoreDescription(url: storeURL)
        // ─── HIPAA: encrypt at rest via FileProtection ──────────────────────
        description.setOption(FileProtectionType.complete as NSObject,
                              forKey: NSPersistentStoreFileProtectionKey)
        // ─── Never sync PHI to CloudKit ────────────────────────────────────
        description.cloudKitContainerOptions = nil
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                // Fail-soft: PHI store unavailable means Care features are
                // degraded, but the rest of the app still runs. Surface in
                // Care home with a banner.
                NSLog("PHIStore failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public var context: NSManagedObjectContext { container.viewContext }

    public func save() {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { NSLog("PHIStore save error: \(error)") }
    }

    /// Wipe every row in every PHI entity. Called on logout.
    public func wipe() {
        for entity in container.managedObjectModel.entities {
            guard let name = entity.name else { continue }
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? container.persistentStoreCoordinator.execute(del, with: context)
        }
        save()
    }

    // MARK: - Default store location

    private static func defaultStoreURL() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("FitFusionPHI.sqlite")
    }

    // MARK: - Programmatic model

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let insurance = NSEntityDescription()
        insurance.name = "PHIInsuranceCardEntity"
        insurance.managedObjectClassName = "NSManagedObject"
        insurance.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("payer", .stringAttributeType),
            attribute("memberId", .stringAttributeType),
            attribute("groupNumber", .stringAttributeType),
            attribute("bin", .stringAttributeType),
            attribute("pcn", .stringAttributeType),
            attribute("rxGrp", .stringAttributeType),
            attribute("capturedAt", .dateAttributeType, optional: false),
        ]

        // Care+ v1 PHI rule (PRIVACY-CARE.md §2): the FHIR `patient` claim
        // is a clinical identifier — must NOT live on the server. Stays
        // here in the on-device PHI store, encrypted at rest.
        let myChart = NSEntityDescription()
        myChart.name = "PHIMyChartIssuerEntity"
        myChart.managedObjectClassName = "NSManagedObject"
        myChart.properties = [
            attribute("issuer", .stringAttributeType, optional: false),
            attribute("displayName", .stringAttributeType, optional: false),
            attribute("patientId", .stringAttributeType),
            attribute("connectedAt", .dateAttributeType, optional: false),
        ]

        let provider = NSEntityDescription()
        provider.name = "PHIProviderEntity"
        provider.managedObjectClassName = "NSManagedObject"
        provider.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("npi", .stringAttributeType, optional: false),
            attribute("name", .stringAttributeType, optional: false),
            attribute("specialty", .stringAttributeType),
            attribute("phone", .stringAttributeType),
            attribute("addressLine", .stringAttributeType),
            attribute("zip", .stringAttributeType),
            attribute("favoritedAt", .dateAttributeType, optional: false),
        ]

        let rpe = NSEntityDescription()
        rpe.name = "PHIRPELogEntity"
        rpe.managedObjectClassName = "NSManagedObject"
        rpe.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("workoutSessionId", .stringAttributeType),
            attribute("rating", .integer16AttributeType, optional: false),
            attribute("loggedAt", .dateAttributeType, optional: false),
            attribute("notes", .stringAttributeType),
        ]

        model.entities = [insurance, myChart, provider, rpe]
        return model
    }

    private static func attribute(_ name: String,
                                  _ type: NSAttributeType,
                                  optional: Bool = true) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        return a
    }
}

// MARK: - Convenience CRUD helpers (small, just enough for week 1 screens)

extension PHIStore {

    @discardableResult
    public func saveInsuranceCard(payer: String?, memberId: String?,
                                  groupNumber: String?, bin: String?,
                                  pcn: String?, rxGrp: String?) -> NSManagedObject? {
        guard let entity = container.managedObjectModel.entitiesByName["PHIInsuranceCardEntity"] else { return nil }
        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(payer, forKey: "payer")
        obj.setValue(memberId, forKey: "memberId")
        obj.setValue(groupNumber, forKey: "groupNumber")
        obj.setValue(bin, forKey: "bin")
        obj.setValue(pcn, forKey: "pcn")
        obj.setValue(rxGrp, forKey: "rxGrp")
        obj.setValue(Date(), forKey: "capturedAt")
        save()
        return obj
    }

    public func latestInsuranceCard() -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "PHIInsuranceCardEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "capturedAt", ascending: false)]
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first
    }

    @discardableResult
    public func favoriteProvider(npi: String, name: String, specialty: String?,
                                 phone: String?, addressLine: String?, zip: String?) -> NSManagedObject? {
        guard let entity = container.managedObjectModel.entitiesByName["PHIProviderEntity"] else { return nil }
        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(npi, forKey: "npi")
        obj.setValue(name, forKey: "name")
        obj.setValue(specialty, forKey: "specialty")
        obj.setValue(phone, forKey: "phone")
        obj.setValue(addressLine, forKey: "addressLine")
        obj.setValue(zip, forKey: "zip")
        obj.setValue(Date(), forKey: "favoritedAt")
        save()
        return obj
    }

    public func favoriteProviders() -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "PHIProviderEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "favoritedAt", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    @discardableResult
    public func logRPE(rating: Int16, workoutSessionId: String?, notes: String?) -> NSManagedObject? {
        guard let entity = container.managedObjectModel.entitiesByName["PHIRPELogEntity"] else { return nil }
        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(workoutSessionId, forKey: "workoutSessionId")
        obj.setValue(rating, forKey: "rating")
        obj.setValue(Date(), forKey: "loggedAt")
        obj.setValue(notes, forKey: "notes")
        save()
        return obj
    }

    public func recentRPELogs(limit: Int = 20) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "PHIRPELogEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "loggedAt", ascending: false)]
        req.fetchLimit = limit
        return (try? context.fetch(req)) ?? []
    }

    // MARK: - MyChart issuer (PHI: patient_id stays on-device only)

    @discardableResult
    public func saveMyChartIssuer(issuer: String, displayName: String,
                                  patientId: String?) -> NSManagedObject? {
        guard let entity = container.managedObjectModel.entitiesByName["PHIMyChartIssuerEntity"] else { return nil }
        // Replace any existing row for this issuer so connect-disconnect-reconnect
        // doesn't accumulate duplicates.
        let req = NSFetchRequest<NSManagedObject>(entityName: "PHIMyChartIssuerEntity")
        req.predicate = NSPredicate(format: "issuer == %@", issuer)
        if let existing = try? context.fetch(req) {
            existing.forEach(context.delete)
        }
        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(issuer, forKey: "issuer")
        obj.setValue(displayName, forKey: "displayName")
        obj.setValue(patientId, forKey: "patientId")
        obj.setValue(Date(), forKey: "connectedAt")
        save()
        return obj
    }

    public func myChartPatientId(issuer: String) -> String? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "PHIMyChartIssuerEntity")
        req.predicate = NSPredicate(format: "issuer == %@", issuer)
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first?.value(forKey: "patientId") as? String
    }
}
#endif
