import XCTest
@testable import Card
import CardCore

@MainActor
final class CardRepositoryTests: XCTestCase {
    private var tempDir: URL!
    private var store: CardStore!
    private var repo: CardRepository!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("repo-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = CardStore(directory: tempDir)
        repo = CardRepository(store: store)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testCaptureProducesARowAtTop() {
        repo.capture(text: "Buy milk")
        XCTAssertEqual(repo.cards.count, 1)
        XCTAssertEqual(repo.cards.first?.text, "Buy milk")
    }

    func testEmptyTextDoesNotCapture() {
        repo.capture(text: "   ")
        XCTAssertTrue(repo.cards.isEmpty)
    }

    func testConvertToTaskKeepsTextAndChangesKind() {
        repo.capture(text: "x")
        let card = repo.cards.first!
        repo.convert(card, to: .task)
        XCTAssertEqual(repo.cards.first?.kind, .task)
        XCTAssertEqual(repo.cards.first?.text, "x")
    }

    func testDeleteRemovesCard() {
        repo.capture(text: "x")
        let card = repo.cards.first!
        repo.delete(card)
        XCTAssertTrue(repo.cards.isEmpty)
    }

    func testEraseAllClearsFeed() {
        repo.capture(text: "a")
        repo.capture(text: "b")
        repo.eraseAll()
        XCTAssertTrue(repo.cards.isEmpty)
    }
}
