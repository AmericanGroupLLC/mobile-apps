import XCTest
@testable import FitFusionCore

final class ExerciseLibraryTests: XCTestCase {

    func testLibraryNonEmpty() {
        XCTAssertGreaterThan(ExerciseLibrary.exercises.count, 30)
    }

    func testFilterByMuscle() {
        let chest = ExerciseLibrary.filter(muscle: .chest)
        XCTAssertFalse(chest.isEmpty)
        XCTAssertTrue(chest.allSatisfy {
            $0.primaryMuscles.contains(.chest) || $0.secondaryMuscles.contains(.chest)
        })
    }

    func testFilterByEquipmentAndDifficulty() {
        let beginnerBodyweight = ExerciseLibrary.filter(
            equipment: .bodyweight, difficulty: .beginner
        )
        XCTAssertFalse(beginnerBodyweight.isEmpty)
        XCTAssertTrue(beginnerBodyweight.allSatisfy {
            $0.equipment == .bodyweight && $0.difficulty == .beginner
        })
    }

    func testExcludeStretches() {
        let withStretches = ExerciseLibrary.filter(includeStretches: true).count
        let withoutStretches = ExerciseLibrary.filter(includeStretches: false).count
        XCTAssertGreaterThan(withStretches, withoutStretches)
    }

    func testSearch() {
        let bench = ExerciseLibrary.search("bench")
        XCTAssertTrue(bench.contains(where: { $0.id == "bench-press" }))
    }

    func testByIdRoundTrip() {
        let id = "deadlift"
        let exercise = ExerciseLibrary.byId(id)
        XCTAssertNotNil(exercise)
        XCTAssertEqual(exercise?.id, id)
    }

    func testEveryExerciseHasInstructions() {
        for ex in ExerciseLibrary.exercises {
            XCTAssertFalse(ex.instructions.isEmpty,
                           "Exercise \(ex.id) has no instructions")
            XCTAssertFalse(ex.primaryMuscles.isEmpty,
                           "Exercise \(ex.id) has no primary muscles")
        }
    }
}
