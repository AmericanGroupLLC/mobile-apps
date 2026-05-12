import XCTest

/// Verifies the Care+ MyChart connect screen surfaces the exact-scope-list
/// UI before launching the OAuth browser. We don't drive the actual
/// `ASWebAuthenticationSession` here (it's a system view), only the
/// pre-flight surface and "Sandbox login" hints.
final class MyChartConnectShowsScopesTests: XCTestCase {

    override func setUpWithError() throws { continueAfterFailure = false }

    func testScopesAndSandboxHintAppear() throws {
        let app = XCUIApplication()
        app.launchEnvironment["FFUI_SKIP_ANIMATIONS"] = "1"
        app.launch()

        // Skip if we're still in onboarding.
        let careTab = app.tabBars.firstMatch.buttons["Care"]
        if !careTab.waitForExistence(timeout: 4) {
            throw XCTSkip("Care tab not visible (likely onboarding).")
        }
        careTab.tap()

        let connectButton = app.buttons["Connect MyChart"]
        if !connectButton.waitForExistence(timeout: 3) {
            throw XCTSkip("MyChart CTA absent — possibly already connected.")
        }
        connectButton.tap()

        XCTAssertTrue(app.staticTexts["What we'll read"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Sandbox login"].exists)
        XCTAssertTrue(app.buttons["Connect with MyChart"].exists)
    }
}
