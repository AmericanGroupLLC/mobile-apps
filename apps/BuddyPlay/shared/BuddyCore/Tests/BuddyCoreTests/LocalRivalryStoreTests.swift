import XCTest
@testable import BuddyCore

final class LocalRivalryStoreTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("buddyplay-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testEmptyOnFirstLoad() throws {
        let store = try LocalRivalryStore(directory: tempDir)
        XCTAssertEqual(store.loadAll().count, 0)
    }

    func testWriteReadIncrement() throws {
        let store = try LocalRivalryStore(directory: tempDir)
        let opp = UUID()
        store.record(opponentId: opp, opponentName: "Sarah", kind: .chess, outcome: .win)
        store.record(opponentId: opp, opponentName: "Sarah", kind: .chess, outcome: .win)
        store.record(opponentId: opp, opponentName: "Sarah", kind: .chess, outcome: .loss)

        let r = store.load(opponentId: opp)
        XCTAssertNotNil(r)
        XCTAssertEqual(r?.perGame[.chess]?.wins, 2)
        XCTAssertEqual(r?.perGame[.chess]?.losses, 1)
        XCTAssertEqual(r?.perGame[.chess]?.draws, 0)
    }

    func testDifferentGamesTallyIndependently() throws {
        let store = try LocalRivalryStore(directory: tempDir)
        let opp = UUID()
        store.record(opponentId: opp, opponentName: "S", kind: .chess, outcome: .win)
        store.record(opponentId: opp, opponentName: "S", kind: .ludo,  outcome: .loss)
        store.record(opponentId: opp, opponentName: "S", kind: .racer, outcome: .draw)
        let r = store.load(opponentId: opp)!
        XCTAssertEqual(r.perGame[.chess]?.wins, 1)
        XCTAssertEqual(r.perGame[.ludo]?.losses, 1)
        XCTAssertEqual(r.perGame[.racer]?.draws, 1)
    }

    func testEraseAllWipes() throws {
        let store = try LocalRivalryStore(directory: tempDir)
        store.record(opponentId: UUID(), opponentName: "Sarah", kind: .chess, outcome: .win)
        XCTAssertGreaterThan(store.loadAll().count, 0)
        store.eraseAll()
        XCTAssertEqual(store.loadAll().count, 0)
    }

    func testCorruptJsonFallsBackToEmpty() throws {
        let store = try LocalRivalryStore(directory: tempDir)
        let url = tempDir.appendingPathComponent("rivalries.json")
        try Data("{not valid json".utf8).write(to: url)
        XCTAssertEqual(store.loadAll().count, 0, "corrupt JSON must not throw — falls back to empty")
    }
}
