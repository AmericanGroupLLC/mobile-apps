import XCTest
@testable import BuddyAICore

final class ModelStoreTests: XCTestCase {

    func testInstallAndRemove() throws {
        let dir = try uniqueTempDir()
        let store = try ModelStore(directory: dir)
        let src = dir.appendingPathComponent("dl.bin")
        try Data("hello".utf8).write(to: src)
        let installed = try store.install(downloaded: src, named: "model.gguf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: installed.path))
        XCTAssertTrue(store.isInstalled(named: "model.gguf"))
        try store.remove(named: "model.gguf")
        XCTAssertFalse(store.isInstalled(named: "model.gguf"))
    }

    func testVerifyEmptySHASkips() throws {
        let dir = try uniqueTempDir()
        let store = try ModelStore(directory: dir)
        let src = dir.appendingPathComponent("dl.bin")
        try Data("anything".utf8).write(to: src)
        try store.install(downloaded: src, named: "model.gguf")
        XCTAssertTrue(store.verify(named: "model.gguf", expectedSHA256: ""))
    }

    func testVerifyMismatchFails() throws {
        let dir = try uniqueTempDir()
        let store = try ModelStore(directory: dir)
        let src = dir.appendingPathComponent("dl.bin")
        try Data("hello".utf8).write(to: src)
        try store.install(downloaded: src, named: "model.gguf")
        XCTAssertFalse(store.verify(named: "model.gguf", expectedSHA256: "deadbeef"))
    }

    private func uniqueTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("oab-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
