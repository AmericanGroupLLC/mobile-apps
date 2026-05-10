import XCTest
@testable import FitFusionCore

final class BiologicalAgeEngineTests: XCTestCase {

    func testFitYoungAdultIsYoungerThanChronological() {
        let inputs = BiologicalAgeEngine.Inputs(
            chronologicalYears: 30, sex: .male,
            restingHR: 52, hrv: 80, vo2Max: 50,
            avgSleepHours: 7.8, bmi: 23,
            bodyFatPct: 0.14, systolicBP: 115, diastolicBP: 75,
            weeklyExerciseMin: 250, stepsPerDay: 11000
        )
        let result = BiologicalAgeEngine.shared.estimate(inputs)
        XCTAssertLessThan(result.biologicalYears, 30)
        XCTAssertGreaterThan(result.confidence, 0.7)
    }

    func testSedentaryAdultIsOlderThanChronological() {
        let inputs = BiologicalAgeEngine.Inputs(
            chronologicalYears: 35, sex: .male,
            restingHR: 78, hrv: 22, vo2Max: 28,
            avgSleepHours: 5.5, bmi: 31,
            bodyFatPct: 0.32, systolicBP: 145, diastolicBP: 92,
            weeklyExerciseMin: 30, stepsPerDay: 3000,
            smoker: true
        )
        let result = BiologicalAgeEngine.shared.estimate(inputs)
        XCTAssertGreaterThan(result.biologicalYears, 35)
    }

    func testConfidenceScalesWithSignals() {
        let bare = BiologicalAgeEngine.shared.estimate(
            .init(chronologicalYears: 40, sex: .female)
        )
        let full = BiologicalAgeEngine.shared.estimate(
            .init(chronologicalYears: 40, sex: .female,
                  restingHR: 60, hrv: 50, vo2Max: 36,
                  avgSleepHours: 7.5, bmi: 22, bodyFatPct: 0.22,
                  systolicBP: 115, diastolicBP: 75,
                  weeklyExerciseMin: 180, stepsPerDay: 9000)
        )
        XCTAssertLessThan(bare.confidence, full.confidence)
    }

    func testFactorOrderingByMagnitude() {
        let inputs = BiologicalAgeEngine.Inputs(
            chronologicalYears: 50, sex: .male,
            restingHR: 80, vo2Max: 25, smoker: true
        )
        let result = BiologicalAgeEngine.shared.estimate(inputs)
        // Smoking is a +6 hit and should land at or near the top.
        XCTAssertEqual(result.factors.first?.name, "Smoking")
    }
}
