import XCTest
@testable import FitFusionCore

@MainActor
final class AdaptivePlannerTests: XCTestCase {

    func testHighReadinessSuggestsHardWorkout() {
        let s = AdaptivePlanner.shared.nextWorkout(for: 90)
        XCTAssertTrue(s.confidence > 0)
        XCTAssertFalse(s.template.id.isEmpty)
        // High readiness should prefer advanced/intermediate templates.
        let allowed: Set<String> = [
            "advanced-strength-45", "tempo-run-25", "full-body-strength-30", "hiit-cardio-15"
        ]
        XCTAssertTrue(allowed.contains(s.template.id),
                      "got \(s.template.id) for high readiness")
    }

    func testLowReadinessSuggestsRecovery() {
        let s = AdaptivePlanner.shared.nextWorkout(for: 25)
        let allowed: Set<String> = ["gentle-yoga-20", "deep-stretch-25",
                                    "easy-run-30", "vinyasa-flow-30"]
        XCTAssertTrue(allowed.contains(s.template.id),
                      "got \(s.template.id) for low readiness")
    }

    func testConfidenceScalesWithDataPoints() {
        let zeroData = AdaptivePlanner.shared.nextWorkout(
            for: .init(readiness: 70, recentHRV: nil, lastSleepHrs: nil,
                       weeklyMinutes: nil, perceivedExertion: nil)
        )
        let fullData = AdaptivePlanner.shared.nextWorkout(
            for: .init(readiness: 70, recentHRV: 55, lastSleepHrs: 7.5,
                       weeklyMinutes: 200, perceivedExertion: 6)
        )
        XCTAssertGreaterThan(fullData.confidence, zeroData.confidence)
    }
}
