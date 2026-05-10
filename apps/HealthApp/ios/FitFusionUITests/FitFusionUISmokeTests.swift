import XCTest

/// Top-level UI smoke flows. Each test launches a fresh app instance with the
/// `-uiTesting` argument so the app can short-circuit any live network calls
/// and start in a clean Guest Mode state (see `FitFusionApp.swift` for the
/// `ProcessInfo.arguments` hook).
final class FitFusionUISmokeTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetState"]
        app.launch()
        return app
    }

    /// Verifies the very first thing a user sees \u{2014} the Login screen with the
    /// new "Continue as Guest" button.
    func testLoginShowsContinueAsGuest() throws {
        let app = launchedApp()
        let guestButton = app.buttons["Continue as Guest"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5),
                      "Continue as Guest button missing on Login")
    }

    /// Tap Continue as Guest \u{2192} verify Onboarding renders.
    func testGuestPathLandsOnOnboarding() throws {
        let app = launchedApp()
        let guestButton = app.buttons["Continue as Guest"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5))
        guestButton.tap()

        // Either the Welcome page (with title) or the dashboard if the user
        // has already onboarded \u{2014} both are valid post-tap states.
        let welcome = app.staticTexts["Welcome to MyHealth"]
        let homeTab = app.tabBars.buttons["Home"]
        let foundOne = welcome.waitForExistence(timeout: 5) || homeTab.waitForExistence(timeout: 5)
        XCTAssertTrue(foundOne, "Neither Welcome screen nor Home tab appeared")
    }

    /// Once on the dashboard, the bottom tab bar should expose every primary tab.
    func testBottomTabBarHasAllPrimaryTabs() throws {
        let app = launchedApp()
        // Bypass onboarding via launch arg if needed
        if app.buttons["Continue as Guest"].waitForExistence(timeout: 3) {
            app.buttons["Continue as Guest"].tap()
        }
        // Skip onboarding flow if it appears
        let enterButton = app.buttons["Enter MyHealth"]
        if enterButton.waitForExistence(timeout: 3) {
            enterButton.tap()
        }

        let tabs = ["Home", "Train", "Diary", "Sleep", "More"]
        for label in tabs {
            let tab = app.tabBars.buttons[label]
            XCTAssertTrue(tab.exists || tab.waitForExistence(timeout: 2),
                          "Tab '\(label)' missing")
        }
    }
}
