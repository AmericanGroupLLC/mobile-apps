import XCTest
@testable import FitFusionCore

final class ModelEncodingTests: XCTestCase {

    func testWorkoutTemplateRoundTrip() throws {
        let original = WorkoutTemplate(
            id: "test-id", name: "Test", category: .strength,
            level: .intermediate, durationMin: 30,
            summary: "summary", activityType: 50
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutTemplate.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testExerciseRoundTrip() throws {
        let original = Exercise(
            id: "ex1", name: "Test Press",
            primary: [.chest], secondary: [.triceps],
            equipment: .barbell, difficulty: .intermediate,
            instructions: ["one", "two"],
            formTips: ["tip"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Exercise.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testLoggedSetRoundTrip() throws {
        let sets = [
            CloudStore.LoggedSet(reps: 10, weight: 60),
            CloudStore.LoggedSet(reps: 8, weight: 65),
        ]
        let data = try JSONEncoder().encode(sets)
        let decoded = try JSONDecoder().decode([CloudStore.LoggedSet].self, from: data)
        XCTAssertEqual(decoded, sets)
    }
}
