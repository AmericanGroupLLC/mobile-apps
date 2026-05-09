import Foundation
import HealthKit
import SwiftUI
import CoreLocation
import FitFusionCore

/// iOS-side HealthKit manager — full read/write set for FitFusion (HRV, sleep stages,
/// dietary correlations, mindful sessions, workouts) plus run summary fetching.
@MainActor
final class iOSHealthKitManager: ObservableObject {
    static let shared = iOSHealthKitManager()
    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var lastError: String?

    private var observers: [HKObserverQuery] = []
    private var anchors: [String: HKQueryAnchor] = [:]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Types

    private var readTypes: Set<HKObjectType> {
        var t: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyMassIndex),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.leanBodyMass),
            HKQuantityType(.height),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleStandTime),
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.flightsClimbed),
            HKQuantityType(.oxygenSaturation),
            HKQuantityType(.vo2Max),
            HKQuantityType(.bloodGlucose),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.bodyTemperature),
            HKQuantityType(.basalBodyTemperature),
            HKQuantityType(.environmentalAudioExposure),
            HKQuantityType(.headphoneAudioExposure),
            HKQuantityType(.uvExposure),
            HKCategoryType(.sleepAnalysis),
            HKCategoryType(.mindfulSession),
            HKCategoryType(.handwashingEvent),
            HKCategoryType(.menstrualFlow),
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
        ]
        if #available(iOS 16.0, *) {
            t.insert(HKQuantityType(.respiratoryRate))
            t.insert(HKQuantityType(.appleSleepingWristTemperature))
            t.insert(HKCategoryType(.appleWalkingSteadinessEvent))
            t.insert(HKCategoryType(.irregularHeartRhythmEvent))
        }
        if #available(iOS 14.0, *) {
            t.insert(HKObjectType.electrocardiogramType())
        }
        if #available(iOS 17.0, *) {
            t.insert(HKSampleType.stateOfMindType())
        }
        return t
    }

    private var writeTypes: Set<HKSampleType> {
        var t: Set<HKSampleType> = [
            HKQuantityType(.dietaryWater),
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.leanBodyMass),
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.bloodGlucose),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKCategoryType(.mindfulSession),
            HKObjectType.workoutType(),
        ]
        if #available(iOS 17.0, *) {
            t.insert(HKSampleType.stateOfMindType())
        }
        return t
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { lastError = "HealthKit not available"; return }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            await refreshTodaySteps()
            startObservers()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Today snapshot

    func refreshTodaySteps() async {
        guard isAvailable else { return }
        let type = HKQuantityType(.stepCount)
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        do {
            if #available(iOS 15.0, *) {
                let descriptor = HKStatisticsQueryDescriptor(
                    predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
                    options: .cumulativeSum
                )
                let result = try await descriptor.result(for: store)
                todaySteps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Observers (mirror watch pattern)

    private func startObservers() {
        let pairs: [(HKQuantityType, String, HKUnit, String)] = [
            (HKQuantityType(.heartRateVariabilitySDNN), "hrv_sdnn",     .secondUnit(with: .milli),                                  "ms"),
            (HKQuantityType(.restingHeartRate),         "resting_hr",   HKUnit.count().unitDivided(by: .minute()),                  "bpm"),
        ]
        for (type, name, unit, label) in pairs {
            registerObserver(type: type, metricName: name, unit: unit, unitLabel: label)
        }
    }

    private func registerObserver(type: HKQuantityType, metricName: String, unit: HKUnit, unitLabel: String) {
        let q = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
            if error == nil {
                Task { await self?.fetchAndSync(type: type, metricName: metricName, unit: unit, unitLabel: unitLabel); completion() }
            } else {
                completion()
            }
        }
        store.execute(q)
        observers.append(q)
        store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
    }

    private func fetchAndSync(type: HKQuantityType, metricName: String, unit: HKUnit, unitLabel: String) async {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(),
            options: []
        )
        let anchor = anchors[metricName]
        if #available(iOS 15.0, *) {
            do {
                let descriptor = HKAnchoredObjectQueryDescriptor(
                    predicates: [.quantitySample(type: type, predicate: predicate)],
                    anchor: anchor,
                    limit: 50
                )
                let r = try await descriptor.result(for: store)
                anchors[metricName] = r.newAnchor
                for sample in r.addedSamples {
                    let value = sample.quantity.doubleValue(for: unit)
                    _ = try? await APIClient.shared.logMetric(type: metricName, value: value, unit: unitLabel)
                }
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    // MARK: - Meal write (HKCorrelation)

    func writeMeal(_ item: NutritionService.FoodItem) async {
        guard isAuthorized else { return }
        let now = Date()
        var samples: Set<HKSample> = []

        func qSample(_ type: HKQuantityType, value: Double, unit: HKUnit) -> HKQuantitySample {
            HKQuantitySample(type: type,
                             quantity: HKQuantity(unit: unit, doubleValue: value),
                             start: now, end: now)
        }

        if item.kcal > 0 {
            samples.insert(qSample(HKQuantityType(.dietaryEnergyConsumed), value: item.kcal, unit: .kilocalorie()))
        }
        if item.protein > 0 {
            samples.insert(qSample(HKQuantityType(.dietaryProtein), value: item.protein, unit: .gram()))
        }
        if item.carbs > 0 {
            samples.insert(qSample(HKQuantityType(.dietaryCarbohydrates), value: item.carbs, unit: .gram()))
        }
        if item.fat > 0 {
            samples.insert(qSample(HKQuantityType(.dietaryFatTotal), value: item.fat, unit: .gram()))
        }
        guard !samples.isEmpty else { return }

        let correlation = HKCorrelation(
            type: HKCorrelationType(.food),
            start: now, end: now,
            objects: samples,
            metadata: [HKMetadataKeyFoodType: item.name]
        )
        do { try await store.save(correlation) }
        catch { lastError = error.localizedDescription }
    }

    // MARK: - Mindful session

    func writeMindfulSession(start: Date, end: Date) async {
        guard isAuthorized else { return }
        let type = HKCategoryType(.mindfulSession)
        let sample = HKCategorySample(type: type, value: 0, start: start, end: end)
        do { try await store.save(sample) }
        catch { lastError = error.localizedDescription }
    }

    // MARK: - Sleep snapshot

    func fetchLastNightSleep() async throws -> SleepSnapshot {
        let type = HKCategoryType(.sleepAnalysis)
        // last night = 6pm yesterday → noon today
        let cal = Calendar.current
        let now = Date()
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let yesterday6pm = cal.date(byAdding: .hour, value: -18, to: noon) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: yesterday6pm, end: noon)

        if #available(iOS 15.0, *) {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.categorySample(type: type, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)],
                limit: 200
            )
            let raw = try await descriptor.result(for: store)
            let stages: [SleepStageSegment] = raw.compactMap { sample in
                guard let stage = SleepStage(rawValue: sample.value) else { return nil }
                return SleepStageSegment(start: sample.startDate, end: sample.endDate, stage: stage)
            }
            return SleepSnapshot(stages: stages)
        }
        return SleepSnapshot(stages: [])
    }

    // MARK: - Run history

    func fetchRecentRuns(limit: Int = 30) async throws -> [RunSummary] {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        if #available(iOS 15.0, *) {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.workout(predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
                limit: limit
            )
            let workouts = try await descriptor.result(for: store)
            var summaries: [RunSummary] = []
            for w in workouts {
                let distanceM = w.totalDistance?.doubleValue(for: .meter()) ?? 0
                let durationSec = w.duration
                let distanceKm = distanceM / 1000.0
                let pace = distanceKm > 0 ? durationSec / distanceKm : 0
                let coords = (try? await fetchRoute(for: w)) ?? []
                summaries.append(.init(
                    id: w.uuid,
                    startDate: w.startDate,
                    duration: durationSec,
                    distanceKm: distanceKm,
                    paceSecPerKm: pace,
                    paceByKm: [],
                    routeCoordinates: coords
                ))
            }
            return summaries
        }
        _ = workoutType; _ = predicate
        return []
    }

    /// Fetch the GPS route polyline associated with a workout, if any. Used by
    /// `RunDetailView` / `RunMapView` to render the route the watch recorded.
    func fetchRoute(for workout: HKWorkout) async throws -> [CLLocationCoordinate2D] {
        // Step 1 — locate the HKWorkoutRoute sample(s) that point at the workout.
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        let routes: [HKWorkoutRoute] = try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: routeType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }
            self.store.execute(q)
        }
        guard !routes.isEmpty else { return [] }

        // Step 2 — stream each route's CLLocations into a single coord array.
        var coords: [CLLocationCoordinate2D] = []
        for route in routes {
            let routeCoords: [CLLocationCoordinate2D] = try await withCheckedThrowingContinuation { cont in
                var collected: [CLLocationCoordinate2D] = []
                let q = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                    if let error { cont.resume(throwing: error); return }
                    if let locations { collected.append(contentsOf: locations.map { $0.coordinate }) }
                    if done { cont.resume(returning: collected) }
                }
                self.store.execute(q)
            }
            coords.append(contentsOf: routeCoords)
        }
        return coords
    }

    // MARK: - Types

    struct RunSummary: Identifiable {
        let id: UUID
        let startDate: Date
        let duration: TimeInterval
        let distanceKm: Double
        let paceSecPerKm: Double
        let paceByKm: [Double]
        let routeCoordinates: [CLLocationCoordinate2D]
    }

    enum SleepStage: Int, CaseIterable, Identifiable {
        case inBed   = 0
        case asleep  = 1
        case awake   = 2
        case core    = 3
        case deep    = 4
        case rem     = 5

        // Map raw HKCategoryValueSleepAnalysis values
        init?(rawValue: Int) {
            switch rawValue {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:               self = .inBed
            case HKCategoryValueSleepAnalysis.awake.rawValue:               self = .awake
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:          self = .core
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:          self = .deep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:           self = .rem
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:   self = .asleep
            default: return nil
            }
        }

        var id: Int { rawValue }
        var label: String {
            switch self {
            case .inBed:   return "In bed"
            case .asleep:  return "Asleep"
            case .awake:   return "Awake"
            case .core:    return "Core"
            case .deep:    return "Deep"
            case .rem:     return "REM"
            }
        }
        var color: Color {
            switch self {
            case .deep:    return .indigo
            case .rem:     return .purple
            case .core:    return .blue
            case .asleep:  return .teal
            case .inBed:   return .gray
            case .awake:   return .orange
            }
        }
    }

    struct SleepStageSegment: Identifiable {
        let id = UUID()
        let start: Date
        let end: Date
        let stage: SleepStage
        var seconds: TimeInterval { end.timeIntervalSince(start) }
    }

    struct SleepSnapshot {
        let stages: [SleepStageSegment]
        var totalHours: Double {
            stages
                .filter { [.core, .deep, .rem, .asleep].contains($0.stage) }
                .reduce(0) { $0 + $1.seconds } / 3600.0
        }
        func totalHours(for stage: SleepStage) -> Double {
            stages.filter { $0.stage == stage }.reduce(0) { $0 + $1.seconds } / 3600.0
        }
    }

    // MARK: - State of Mind (iOS 18+)

    /// Write a 2-axis State of Mind sample (valence + arousal) to Apple Health.
    /// `valence` ∈ [-1, 1] (very unpleasant → very pleasant);
    /// `arousal` is mapped via Apple's `HKStateOfMind.Label` set picked by the caller.
    @available(iOS 18.0, *)
    func writeStateOfMind(label: HKStateOfMind.Label,
                          valence: Double,
                          kind: HKStateOfMind.Kind = .momentaryEmotion,
                          associations: [HKStateOfMind.Association] = []) async {
        guard isAuthorized else { return }
        let sample = HKStateOfMind(date: Date(),
                                   kind: kind,
                                   valence: max(-1, min(1, valence)),
                                   labels: [label],
                                   associations: associations)
        do { try await store.save(sample) }
        catch { lastError = error.localizedDescription }
    }

    /// Recent State of Mind entries (rolling window).
    @available(iOS 18.0, *)
    func readRecentStateOfMind(daysBack: Int = 7) async throws -> [HKStateOfMind] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -daysBack, to: Date()) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.stateOfMind(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 100
        )
        return try await descriptor.result(for: store)
    }

    // MARK: - Helpers for RecoveryService

    func averageHRV(daysBack: Int = 7) async -> Double? {
        await averageQuantity(type: HKQuantityType(.heartRateVariabilitySDNN),
                              unit: .secondUnit(with: .milli),
                              daysBack: daysBack)
    }

    func averageRestingHR(daysBack: Int = 7) async -> Double? {
        await averageQuantity(type: HKQuantityType(.restingHeartRate),
                              unit: HKUnit.count().unitDivided(by: .minute()),
                              daysBack: daysBack)
    }

    private func averageQuantity(type: HKQuantityType, unit: HKUnit, daysBack: Int) async -> Double? {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -daysBack, to: Date()) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        if #available(iOS 15.0, *) {
            do {
                let descriptor = HKStatisticsQueryDescriptor(
                    predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
                    options: .discreteAverage
                )
                let result = try await descriptor.result(for: store)
                return result?.averageQuantity()?.doubleValue(for: unit)
            } catch {
                return nil
            }
        }
        return nil
    }
}
