import XCTest
@testable import CardCore

final class CardStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("CardStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }
    }

    func testLoadFromMissingFileReturnsEmpty() {
        let store = CardStore(directory: tempDir, filename: "missing.json")
        XCTAssertTrue(store.load().isEmpty)
    }

    func testSaveThenLoadRoundTrips() throws {
        let store = CardStore(directory: tempDir, filename: "feed.json")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cards = [
            Card(text: "buy milk", kind: .task, createdAt: now, updatedAt: now),
            Card(text: "call mom", kind: .reminder,
                 reminderAt: now.addingTimeInterval(3600),
                 createdAt: now, updatedAt: now)
        ]
        try store.save(cards)
        let loaded = store.load()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].text, "buy milk")
        XCTAssertEqual(loaded[1].kind, .reminder)
    }

    func testSaveCreatesParentDirectory() throws {
        let nested = tempDir.appendingPathComponent("nested/dir", isDirectory: true)
        let store = CardStore(directory: nested, filename: "feed.json")
        try store.save([Card(text: "x")])
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.appendingPathComponent("feed.json").path))
    }

    func testCorruptFileReturnsEmptyInsteadOfCrashing() throws {
        let url = tempDir.appendingPathComponent("feed.json")
        try "not valid json".write(to: url, atomically: true, encoding: .utf8)
        let store = CardStore(directory: tempDir, filename: "feed.json")
        XCTAssertTrue(store.load().isEmpty)
    }

    func testEmptySaveProducesEmptyArrayLoad() throws {
        let store = CardStore(directory: tempDir, filename: "feed.json")
        try store.save([])
        XCTAssertTrue(store.load().isEmpty)
    }
}
