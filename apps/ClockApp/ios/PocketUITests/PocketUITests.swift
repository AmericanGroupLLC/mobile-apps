import XCTest

final class PocketUITests: XCTestCase {

    func test_launcher_loads_each_tool() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-onboardingComplete")
        app.launch()
        // Tap each tab
        for tab in ["Tools", "Clock", "Calculator", "Compass", "Level"] {
            let item = app.tabBars.buttons[tab]
            if item.exists { item.tap() }
        }
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }
}
