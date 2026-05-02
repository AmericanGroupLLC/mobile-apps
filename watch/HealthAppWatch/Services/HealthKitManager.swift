import Foundation
import HealthKit
import FitFusionCore

/// Manages HealthKit authorization, observer queries, and pushes new samples
/// to the FitFusion backend so all metrics show up in the user's profile.
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var lastSyncSummary: String?
    @Published var lastError: String?

    // MARK: - Types we read
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.bodyMass),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.distanceWalkingRunning),
            HKCategoryType(.sleepAnalysis),
            HKCategoryType(.mindfulSession),
        ]
        if #available(watchOS 9.0, iOS 16.0, *) {
            types.insert(HKQuantityType(.respiratoryRate))
        }
        return types
    }

    // MARK: - Types we write
    private var writeTypes: Set<HKSampleType> {
        [
            HKQuantityType(.dietaryWater),
            HKQuantityType(.bodyMass),
            HKCategoryType(.mindfulSession),
            HKObjectType.workoutType(),
        ]
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization
    func requestAuthorization() async {
        guard isAvailable else {
            lastError = "HealthKit not available on this device"
            return
        }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            startObservers()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Observer queries (background delivery)
    private var observers: [HKObserverQuery] = []

    func startObservers() {
        guard isAuthorized else { return }

        let pairs: [(HKQuantityType, String, HKUnit, String)] = [
            (HKQuantityType(.stepCount),                "steps",        .count(),                                       "steps"),
            (HKQuantityType(.heartRate),                "heart_rate",   HKUnit.count().unitDivided(by: .minute()),       "bpm"),
            (HKQuantityType(.bodyMass),                 "weight",       .gramUnit(with: .kilo),                          "kg"),
            (HKQuantityType(.dietaryWater),             "water",        .literUnit(with: .milli),                        "ml"),
            (HKQuantityType(.activeEnergyBurned),       "active_energy", .kilocalorie(),                                 "kcal"),
            (HKQuantityType(.heartRateVariabilitySDNN), "hrv_sdnn",     .secondUnit(with: .milli),                       "ms"),
            (HKQuantityType(.restingHeartRate),         "resting_hr",   HKUnit.count().unitDivided(by: .minute()),       "bpm"),
        ]

        for (type, metricName, unit, unitLabel) in pairs {
            registerObserver(type: type, metricName: metricName, unit: unit, unitLabel: unitLabel)
        }
        registerSleepObserver()
    }

    private func registerObserver(type: HKQuantityType, metricName: String, unit: HKUnit, unitLabel: String) {
        let q = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                Task { @MainActor in self?.lastError = error.localizedDescription }
                completion()
                return
            }
            Task {
                await self?.fetchAndSync(type: type, metricName: metricName, unit: unit, unitLabel: unitLabel)
                completion()
            }
        }
        store.execute(q)
        observers.append(q)
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
    }

    private func registerSleepObserver() {
        let type = HKCategoryType(.sleepAnalysis)
        let q = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
            if error == nil {
                Task { await self?.fetchSleep(); completion() }
            } else {
                completion()
            }
        }
        store.execute(q)
        observers.append(q)
        store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
    }

    // MARK: - Fetch + sync helpers
    private var anchors: [String: HKQueryAnchor] = [:]

    private func fetchAndSync(type: HKQuantityType, metricName: String, unit: HKUnit, unitLabel: String) async {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(),
            options: []
        )
        let anchor = anchors[metricName]
        let result: (HKAnchoredObjectQueryDescriptor<HKQuantitySample>.Result)?
        if #available(watchOS 9.0, iOS 15.0, *) {
            do {
                let descriptor = HKAnchoredObjectQueryDescriptor(
                    predicates: [.quantitySample(type: type, predicate: predicate)],
                    anchor: anchor,
                    limit: 50
                )
                let r = try await descriptor.result(for: store)
                result = r
                anchors[metricName] = r.newAnchor
                await pushSamples(r.addedSamples, metricName: metricName, unit: unit, unitLabel: unitLabel)
            } catch {
                lastError = error.localizedDescription
                _ = result
            }
        }
    }

    private func pushSamples(_ samples: [HKQuantitySample], metricName: String, unit: HKUnit, unitLabel: String) async {
        guard !samples.isEmpty else { return }
        var ok = 0
        for sample in samples {
            let value = sample.quantity.doubleValue(for: unit)
            do {
                _ = try await APIClient.shared.logMetric(type: metricName, value: value, unit: unitLabel)
                ok += 1
            } catch {
                // continue
            }
        }
        lastSyncSummary = "Synced \(ok) \(metricName) samples"
    }

    private func fetchSleep() async {
        let type = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(),
            options: []
        )
        if #available(watchOS 9.0, iOS 15.0, *) {
            do {
                let descriptor = HKSampleQueryDescriptor(
                    predicates: [.categorySample(type: type, predicate: predicate)],
                    sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
                    limit: 20
                )
                let samples = try await descriptor.result(for: store)
                let totalSeconds = samples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let hours = totalSeconds / 3600
                if hours > 0 {
                    _ = try await APIClient.shared.logMetric(type: "sleep_hrs", value: hours, unit: "hr")
                    lastSyncSummary = String(format: "Synced %.1f hr sleep", hours)
                }
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    // MARK: - Write helpers (called when user logs from inside the app)
    func writeWater(ml: Double) async {
        guard isAuthorized else { return }
        let qty = HKQuantity(unit: .literUnit(with: .milli), doubleValue: ml)
        let sample = HKQuantitySample(type: HKQuantityType(.dietaryWater),
                                      quantity: qty,
                                      start: Date(), end: Date())
        try? await store.save(sample)
    }

    func writeWeight(kg: Double) async {
        guard isAuthorized else { return }
        let qty = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: HKQuantityType(.bodyMass),
                                      quantity: qty,
                                      start: Date(), end: Date())
        try? await store.save(sample)
    }
}
