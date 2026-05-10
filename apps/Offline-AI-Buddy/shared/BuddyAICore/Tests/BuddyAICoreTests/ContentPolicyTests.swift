import XCTest
@testable import BuddyAICore

final class ContentPolicyTests: XCTestCase {

    func testAdultProfilePassesEverythingThrough() {
        let policy = ContentPolicy(language: .en, isKidSafe: false)
        let r = policy.filter("You should kill the bug in the code.")
        XCTAssertFalse(r.blocked)
        XCTAssertEqual(r.filtered, "You should kill the bug in the code.")
    }

    func testKidSafeBlocksViolentEnglish() {
        let policy = ContentPolicy(language: .en, isKidSafe: true)
        let r = policy.filter("Let's play a game where we kill people.")
        XCTAssertTrue(r.blocked)
        XCTAssertTrue(r.filtered.contains("Let's pick a different topic"))
    }

    func testKidSafePassesAgeAppropriate() {
        let policy = ContentPolicy(language: .en, isKidSafe: true)
        let r = policy.filter("Once upon a time there was a friendly dragon.")
        XCTAssertFalse(r.blocked)
    }

    func testKidSafeBlocksHindiViolence() {
        let policy = ContentPolicy(language: .hi, isKidSafe: true)
        let r = policy.filter("उसे मारना नहीं चाहिए।")
        XCTAssertTrue(r.blocked)
    }

    func testKidSafeBlocksMandarinViolence() {
        let policy = ContentPolicy(language: .zh, isKidSafe: true)
        let r = policy.filter("不要杀人。")
        XCTAssertTrue(r.blocked)
    }

    func testKidSafeBlocksFrenchProfanity() {
        let policy = ContentPolicy(language: .fr, isKidSafe: true)
        let r = policy.filter("c'est de la merde")
        XCTAssertTrue(r.blocked)
    }

    func testKidSafeBlocksSpanishAlcohol() {
        let policy = ContentPolicy(language: .es, isKidSafe: true)
        let r = policy.filter("Tomemos cerveza juntos")
        XCTAssertTrue(r.blocked)
    }

    func testIdempotenceOnAlreadyFiltered() {
        let policy = ContentPolicy(language: .en, isKidSafe: true)
        let r1 = policy.filter("Let's discuss weapons.")
        XCTAssertTrue(r1.blocked)
        let r2 = policy.filter(r1.filtered)
        XCTAssertFalse(r2.blocked, "filtered output should not re-trigger the filter")
    }
}
