import XCTest
@testable import FitFusionCore

final class WorkoutProgramsTests: XCTestCase {

    func testAllProgramsResolveExercises() {
        for program in WorkoutPrograms.all {
            for day in program.days {
                for id in day.exerciseIds {
                    XCTAssertNotNil(ExerciseLibrary.byId(id),
                                    "Program \(program.id), day \(day.name) references unknown exercise \(id)")
                }
            }
        }
    }

    func testExpectedProgramsExist() {
        XCTAssertNotNil(WorkoutPrograms.byId("ppl"))
        XCTAssertNotNil(WorkoutPrograms.byId("upper-lower"))
        XCTAssertNotNil(WorkoutPrograms.byId("full-body"))
        XCTAssertNotNil(WorkoutPrograms.byId("beginner-strength"))
    }

    func testProgramShape() {
        for p in WorkoutPrograms.all {
            XCTAssertGreaterThan(p.weeks, 0)
            XCTAssertGreaterThan(p.daysPerWeek, 0)
            XCTAssertFalse(p.days.isEmpty, "Program \(p.id) has no days")
            for d in p.days {
                XCTAssertGreaterThan(d.sets, 0)
                XCTAssertGreaterThan(d.restSeconds, 0)
                XCTAssertFalse(d.exerciseIds.isEmpty)
            }
        }
    }
}
