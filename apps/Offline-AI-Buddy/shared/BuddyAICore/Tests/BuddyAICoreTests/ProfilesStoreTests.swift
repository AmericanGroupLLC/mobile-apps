import XCTest
@testable import BuddyAICore

final class ProfilesStoreTests: XCTestCase {

    func testRoundTripAddAndLoad() throws {
        let dir = try uniqueTempDir()
        let store = try ProfilesStore(directory: dir)
        let p = Profile(name: "Sri", kind: .adult)
        try store.add(p)
        let all = store.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Sri")
    }

    func testDuplicateThrows() throws {
        let dir = try uniqueTempDir()
        let store = try ProfilesStore(directory: dir)
        let p = Profile(name: "Sri", kind: .adult)
        try store.add(p)
        XCTAssertThrowsError(try store.add(p))
    }

    func testCorruptJsonFallsBackToEmpty() throws {
        let dir = try uniqueTempDir()
        try Data("not json".utf8).write(to: dir.appendingPathComponent("profiles.json"))
        let store = try ProfilesStore(directory: dir)
        XCTAssertEqual(store.loadAll(), [])
    }

    func testPinHashRoundTrip() throws {
        let dir = try uniqueTempDir()
        let store = try ProfilesStore(directory: dir)
        let salt = ProfilesStore.newSaltHex()
        let hash = ProfilesStore.pbkdf2Hex(pin: "1234", saltHex: salt)
        let p = Profile(name: "Kid", kind: .kidSafe, pinHash: hash, pinSalt: salt)
        try store.add(p)
        XCTAssertTrue(try store.verify(pin: "1234", for: p.id))
        XCTAssertFalse(try store.verify(pin: "0000", for: p.id))
    }

    private func uniqueTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("oab-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
