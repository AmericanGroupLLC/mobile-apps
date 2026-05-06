import XCTest

final class BuddyPlayUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLaunchAndNavigateTabs() throws {
        let app = XCUIApplication()
        app.launch()

        // Home tab is the default.
        XCTAssertTrue(app.staticTexts["BuddyPlay"].waitForExistence(timeout: 5))

        // Switch to Rivalries tab.
        app.tabBars.buttons["Rivalries"].tap()
        XCTAssertTrue(app.staticTexts["No matches yet"].waitForExistence(timeout: 5))

        // Switch to Settings tab.
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["BuddyPlay does not send any data."].waitForExistence(timeout: 5))
    }

    func testJoinNearbyButtonPresentsLobby() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Play"].tap()
        let joinButton = app.buttons["Join Nearby Game"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 5))
        joinButton.tap()
        XCTAssertTrue(app.navigationBars["Join Nearby"].waitForExistence(timeout: 5))
    }
}
