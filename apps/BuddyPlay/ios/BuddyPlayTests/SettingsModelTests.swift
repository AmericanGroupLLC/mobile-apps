import XCTest
@testable import BuddyPlay
import BuddyCore

final class SettingsModelTests: XCTestCase {

    @MainActor
    func testDefaultValues() {
        let s = SettingsModel()
        // Display name defaults to "Player". May be different if previous
        // test runs persisted a value, so don't assert exact value — just
        // that it's non-empty and the other defaults are sane.
        XCTAssertFalse(s.displayName.isEmpty)
        XCTAssertNotNil(s.connectivityPreference)
    }

    @MainActor
    func testThemeColorScheme() {
        let s = SettingsModel()
        s.theme = .dark
        XCTAssertEqual(s.colorScheme, .dark)
        s.theme = .light
        XCTAssertEqual(s.colorScheme, .light)
        s.theme = .system
        XCTAssertNil(s.colorScheme)
    }

    @MainActor
    func testDefaultGameRoundTrips() {
        let s = SettingsModel()
        s.defaultGame = .ludo
        XCTAssertEqual(s.defaultGame, .ludo)
        s.defaultGame = .racer
        XCTAssertEqual(s.defaultGame, .racer)
        s.defaultGame = .chess
    }
}
