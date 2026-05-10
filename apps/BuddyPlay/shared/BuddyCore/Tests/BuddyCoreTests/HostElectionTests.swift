import XCTest
@testable import BuddyCore

final class HostElectionTests: XCTestCase {

    private func peer(_ uuid: String, platform: Peer.Platform = .ios, name: String = "p") -> Peer {
        Peer(id: UUID(uuidString: uuid)!, displayName: name, platform: platform, lastSeenAt: Date(timeIntervalSince1970: 0))
    }

    func testLexicographicallySmallerIdWins() {
        let a = peer("00000000-0000-0000-0000-000000000001")
        let b = peer("00000000-0000-0000-0000-000000000002")
        XCTAssertEqual(HostElection.host(between: a, b).id, a.id)
        XCTAssertEqual(HostElection.host(between: b, a).id, a.id, "must be symmetric")
        XCTAssertEqual(HostElection.guest(between: a, b).id, b.id)
    }

    func testPlatformTiebreakOnSameUUID() {
        let id = UUID()
        let aIos = Peer(id: id, displayName: "A", platform: .ios, lastSeenAt: Date())
        let bAndroid = Peer(id: id, displayName: "B", platform: .android, lastSeenAt: Date())
        XCTAssertEqual(HostElection.host(between: aIos, bAndroid).platform, .ios)
        XCTAssertEqual(HostElection.host(between: bAndroid, aIos).platform, .ios)
    }

    func testDeterministicOver100Pairs() {
        for _ in 0..<100 {
            let a = peer(UUID().uuidString)
            let b = peer(UUID().uuidString)
            let h1 = HostElection.host(between: a, b)
            let h2 = HostElection.host(between: b, a)
            XCTAssertEqual(h1.id, h2.id)
        }
    }
}
