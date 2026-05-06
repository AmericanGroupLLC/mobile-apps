import XCTest

final class OfflineAIBuddyUITests: XCTestCase {
    func testLaunchesAndShowsHomeOrOnboarding() {
        let app = XCUIApplication()
        app.launch()
        // Either the OnboardingFlow's "Welcome" copy is visible (fresh
        // install) or HomeScreen's title is shown (already onboarded).
        let welcome = app.staticTexts["Welcome to Offline AI Buddy"]
        let home = app.navigationBars["Offline AI Buddy"]
        let appeared = welcome.waitForExistence(timeout: 5)
            || home.waitForExistence(timeout: 5)
        XCTAssertTrue(appeared)
    }
}
