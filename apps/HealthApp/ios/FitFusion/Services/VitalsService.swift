import Foundation
import HealthKit
import FitFusionCore

/// Aggregates every supported HealthKit metric into a single
/// `VitalsSnapshot` ready for the on-device `BiologicalAgeEngine` and the
/// "Vitals" surface on the iPhone.
///
/// **Honest scope:**
/// - HealthKit-backed (sensor + manual entries): HR, RHR, HRV, SpO\u{2082}, VO\u{2082}Max,
///   ECG, irregular rhythm, body mass / fat / lean / BMI, blood pressure,
///   blood glucose, body / wrist temperature, env audio, respiratory rate,
///   handwashing count, walking steadiness events, daily steps, exercise min,
///   active + basal calories, sleep stages.
/// - **Not sensorable on iOS Apple Watch** (manual / N/A): hydration *intake*
///   (manual via dietaryWater), body water %, snoring, continuous BP.
///   These surface in the UI with a clear "tap to log" or "not available"
///   affordance.
@MainActor
final class VitalsService: ObservableObject {

    static let shared = VitalsService()
    private init() {}

    private let store = HKHealthStore()

    @Published var snapshot = VitalsSnapshot()
    @Published var isRefreshing = false
    @Published var lastError: String?

    /// Pull the latest available value for every type into the published snapshot.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        var s = VitalsSnapshot()

        s.heartRate          = await latestQuantity(.heartRate, unit: bpm)
        s.restingHR          = await latestQuantity(.restingHeartRate, unit: bpm)
        s.hrv                = await averageQuantity(.heartRateVariabilitySDNN,
                                                     unit: .secondUnit(with: .milli),
                                                     daysBack: 7)
        s.spo2               = await latestQuantity(.oxygenSaturation, unit: .percent())
        s.vo2Max             = await latestQuantity(.vo2Max,
                                                    unit: HKUnit.literUnit(with: .milli)
                                                        .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                                                        .unitDivided(by: .minute()))
        s.weight             = await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        s.bodyFatPct         = await latestQuantity(.bodyFatPercentage, unit: .percent())
        s.leanMassKg         = await latestQuantity(.leanBodyMass, unit: .gramUnit(with: .kilo))
        s.heightCm           = (await latestQuantity(.height, unit: .meterUnit(with: .centi)))
        s.systolicBP         = await latestQuantity(.bloodPressureSystolic, unit: mmHg)
        s.diastolicBP        = await latestQuantity(.bloodPressureDiastolic, unit: mmHg)
        s.glucoseMgDl        = await latestQuantity(.bloodGlucose,
                                                    unit: HKUnit.gramUnit(with: .milli)
                                                        .unitDivided(by: HKUnit.literUnit(with: .deci)))
        s.bodyTempC          = await latestQuantity(.bodyTemperature, unit: .degreeCelsius())
        s.audioExposureDb    = await latestQuantity(.environmentalAudioExposure,
                                                    unit: HKUnit(from: "dBASPL"))
        s.uvExposureIndex    = await latestQuantity(.uvExposure, unit: .count())
        s.todaySteps         = Int(await sumToday(.stepCount, unit: .count()) ?? 0)
        s.distanceKmToday    = (await sumToday(.distanceWalkingRunning, unit: .meter()) ?? 0) / 1000
        s.activeKcalToday    = await sumToday(.activeEnergyBurned, unit: .kilocalorie())
        s.basalKcalToday     = await sumToday(.basalEnergyBurned, unit: .kilocalorie())
        s.exerciseMinToday   = await sumToday(.appleExerciseTime, unit: .minute())
        s.flightsClimbed     = await sumToday(.flightsClimbed, unit: .count())
        s.dietaryWaterMlToday = (await sumToday(.dietaryWater, unit: .literUnit(with: .milli))) ?? 0

        if #available(iOS 16.0, *) {
            s.respiratoryRate = await latestQuantity(.respiratoryRate,
                                                     unit: HKUnit.count().unitDivided(by: .minute()))
            s.wristTempDeltaC = await latestQuantity(.appleSleepingWristTemperature,
                                                     unit: .degreeCelsius())
        }

        // ECG + irregular rhythm event count over the past 7 days.
        s.ecgCountWeek = await ecgCountLast(days: 7)
        if #available(iOS 16.0, *) {
            s.irregularRhythmCount = await categoryCount(.irregularHeartRhythmEvent, daysBack: 7)
            s.unsteadyEvents       = await categoryCount(.appleWalkingSteadinessEvent, daysBack: 7)
        }
        s.handwashCountToday = await categoryCountToday(.handwashingEvent)

        // Sleep snapshot \u{2014} reuse existing helper.
        if let sleep = try? await iOSHealthKitManager.shared.fetchLastNightSleep() {
            s.lastNightSleepHrs = sleep.totalHours
            s.deepSleepHrs = sleep.totalHours(for: .deep)
            s.remSleepHrs = sleep.totalHours(for: .rem)
        }

        // Derived BMI when both height + weight present.
        if let h = s.heightCm, let w = s.weight, h > 0 {
            let m = h / 100
            s.bmi = w / (m * m)
        }

        snapshot = s
    }

    // MARK: - Manual writers

    func writeBloodPressure(systolic: Double, diastolic: Double, when: Date = Date()) async {
        let sysSample = HKQuantitySample(type: HKQuantityType(.bloodPressureSystolic),
                                         quantity: HKQuantity(unit: mmHg, doubleValue: systolic),
                                         start: when, end: when)
        let diaSample = HKQuantitySample(type: HKQuantityType(.bloodPressureDiastolic),
                                         quantity: HKQuantity(unit: mmHg, doubleValue: diastolic),
                                         start: when, end: when)
        let correlation = HKCorrelation(type: HKCorrelationType(.bloodPressure),
                                        start: when, end: when,
                                        objects: [sysSample, diaSample])
        do { try await store.save(correlation) }
        catch { lastError = error.localizedDescription }
    }

    func writeGlucose(mgDl: Double, when: Date = Date()) async {
        let unit = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
        let sample = HKQuantitySample(type: HKQuantityType(.bloodGlucose),
                                      quantity: HKQuantity(unit: unit, doubleValue: mgDl),
                                      start: when, end: when)
        do { try await store.save(sample) }
        catch { lastError = error.localizedDescription }
    }

    func writeBodyComposition(fatPct: Double?, leanKg: Double?, when: Date = Date()) async {
        var samples: [HKQuantitySample] = []
        if let fp = fatPct {
            samples.append(HKQuantitySample(type: HKQuantityType(.bodyFatPercentage),
                                            quantity: HKQuantity(unit: .percent(), doubleValue: fp),
                                            start: when, end: when))
        }
        if let lm = leanKg {
            samples.append(HKQuantitySample(type: HKQuantityType(.leanBodyMass),
                                            quantity: HKQuantity(unit: .gramUnit(with: .kilo),
                                                                 doubleValue: lm),
                                            start: when, end: when))
        }
        guard !samples.isEmpty else { return }
        do { try await store.save(samples) }
        catch { lastError = error.localizedDescription }
    }

    // MARK: - Internal queries

    private let bpm: HKUnit = HKUnit.count().unitDivided(by: .minute())
    private let mmHg: HKUnit = HKUnit.millimeterOfMercury()

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(id)
        return await withCheckedContinuation { cont in
            let descriptor = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                           sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                                                              ascending: false)]) { _, samples, _ in
                let v = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                cont.resume(returning: v)
            }
            self.store.execute(descriptor)
        }
    }

    private func sumToday(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(id)
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        if #available(iOS 15.0, *) {
            do {
                let descriptor = HKStatisticsQueryDescriptor(
                    predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
                    options: .cumulativeSum
                )
                let r = try await descriptor.result(for: store)
                return r?.sumQuantity()?.doubleValue(for: unit)
            } catch { return nil }
        }
        return nil
    }

    private func averageQuantity(_ id: HKQuantityTypeIdentifier,
                                 unit: HKUnit, daysBack: Int) async -> Double? {
        let type = HKQuantityType(id)
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -daysBack, to: Date()) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        if #available(iOS 15.0, *) {
            do {
                let descriptor = HKStatisticsQueryDescriptor(
                    predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
                    options: .discreteAverage
                )
                let r = try await descriptor.result(for: store)
                return r?.averageQuantity()?.doubleValue(for: unit)
            } catch { return nil }
        }
        return nil
    }

    private func categoryCount(_ id: HKCategoryTypeIdentifier, daysBack: Int) async -> Int {
        let type = HKCategoryType(id)
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -daysBack, to: Date()) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate,
                                  limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: samples?.count ?? 0)
            }
            self.store.execute(q)
        }
    }

    private func categoryCountToday(_ id: HKCategoryTypeIdentifier) async -> Int {
        let type = HKCategoryType(id)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate,
                                  limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: samples?.count ?? 0)
            }
            self.store.execute(q)
        }
    }

    private func ecgCountLast(days: Int) async -> Int {
        guard #available(iOS 14.0, *) else { return 0 }
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: HKObjectType.electrocardiogramType(),
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: samples?.count ?? 0)
            }
            self.store.execute(q)
        }
    }
}

// MARK: - Snapshot model

struct VitalsSnapshot: Equatable {
    // Cardio
    var heartRate: Double?
    var restingHR: Double?
    var hrv: Double?
    var spo2: Double?
    var vo2Max: Double?
    var ecgCountWeek: Int = 0
    var irregularRhythmCount: Int = 0

    // Body composition
    var weight: Double?           // kg
    var bodyFatPct: Double?       // 0\u{2013}1
    var leanMassKg: Double?
    var heightCm: Double?
    var bmi: Double?

    // BP / glucose / temp \u{2014} manual or sensor
    var systolicBP: Double?
    var diastolicBP: Double?
    var glucoseMgDl: Double?
    var bodyTempC: Double?
    var wristTempDeltaC: Double?

    // Activity / today
    var todaySteps: Int = 0
    var distanceKmToday: Double = 0
    var activeKcalToday: Double?
    var basalKcalToday: Double?
    var exerciseMinToday: Double?
    var flightsClimbed: Double?
    var dietaryWaterMlToday: Double = 0

    // Sleep
    var lastNightSleepHrs: Double?
    var deepSleepHrs: Double?
    var remSleepHrs: Double?

    // Environmental + safety
    var audioExposureDb: Double?
    var uvExposureIndex: Double?
    var respiratoryRate: Double?
    var unsteadyEvents: Int = 0
    var handwashCountToday: Int = 0

    /// Body water percentage \u{2014} NOT sensorable; only available via manual entry
    /// or external smart-scale.
    var bodyWaterPct: Double?
}
