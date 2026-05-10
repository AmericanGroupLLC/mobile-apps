import XCTest

final class CardUITests: XCTestCase {
    func testCaptureLoop() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest"]
        app.launch()

        // If the onboarding gate is up, blow through it.
        let openButton = app.buttons["Open Card"]
        if openButton.waitForExistence(timeout: 2) {
            // Swipe through pages
            if app.buttons["Continue"].exists { app.buttons["Continue"].tap() }
            if app.buttons["Skip for now"].exists { app.buttons["Skip for now"].tap() }
            if openButton.exists { openButton.tap() }
        }

        let composer = app.textFields["composer.textField"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText("Buy milk")
        app.buttons["composer.sendButton"].tap()
        XCTAssertTrue(app.staticTexts["Buy milk"].waitForExistence(timeout: 2))
    }
}
