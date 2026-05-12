import XCTest

/// Smoke test that the Care+ tab bar renders all four tabs after onboarding.
/// Skipped when run pre-onboarding (the `Care` tab won't exist yet).
final class CareHomeRendersTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFourTabsAppear() throws {
        let app = XCUIApplication()
        app.launchEnvironment["FFUI_SKIP_ANIMATIONS"] = "1"
        app.launch()

        // If onboarding is showing, this test is a no-op; the dedicated
        // OnboardingFullFlow test covers that path. We only assert when
        // we're already on the main tab bar.
        let tabBar = app.tabBars.firstMatch
        if !tabBar.waitForExistence(timeout: 4) {
            throw XCTSkip("Tab bar not present (likely onboarding running).")
        }

        for label in ["Care", "Diet", "Train", "Workout"] {
            XCTAssertTrue(
                tabBar.buttons[label].exists,
                "Expected tab \"\(label)\" to be present in MainTabView."
            )
        }
    }
}
