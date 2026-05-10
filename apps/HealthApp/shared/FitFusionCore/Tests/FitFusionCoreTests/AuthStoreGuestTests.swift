import XCTest
@testable import FitFusionCore

final class AuthStoreGuestTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset state between tests so each runs clean.
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "user")
        UserDefaults.standard.removeObject(forKey: "token")
    }

    @MainActor
    func testGuestModeFlipsAuthenticated() {
        let auth = AuthStore()
        XCTAssertFalse(auth.isAuthenticated)
        XCTAssertFalse(auth.isGuest)

        auth.continueAsGuest()

        XCTAssertTrue(auth.isAuthenticated)
        XCTAssertTrue(auth.isGuest)
        XCTAssertTrue(APIClient.shared.isGuest)
    }

    @MainActor
    func testGuestModePersistsAcrossInit() {
        let auth1 = AuthStore()
        auth1.continueAsGuest()

        let auth2 = AuthStore()  // simulates a relaunch
        XCTAssertTrue(auth2.isAuthenticated)
        XCTAssertTrue(auth2.isGuest)
    }

    @MainActor
    func testLogoutClearsGuestFlag() {
        let auth = AuthStore()
        auth.continueAsGuest()
        XCTAssertTrue(auth.isGuest)

        auth.logout()

        XCTAssertFalse(auth.isAuthenticated)
        XCTAssertFalse(auth.isGuest)
        XCTAssertFalse(APIClient.shared.isGuest)
    }
}
