import XCTest

/// Drill into Vitals \u{2192} Biological Age and verify the bio-age estimator UI
/// renders with the default chronological age slider.
final class BiologicalAgeUITests: XCTestCase {

    override func setUpWithError() throws { continueAfterFailure = false }

    func testBiologicalAgeFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetState"]
        app.launch()

        if app.buttons["Continue as Guest"].waitForExistence(timeout: 5) {
            app.buttons["Continue as Guest"].tap()
        }
        if app.buttons["Enter MyHealth"].waitForExistence(timeout: 3) {
            app.buttons["Enter MyHealth"].tap()
        }

        // Land on Home; tap Vitals card.
        let vitalsCard = app.buttons["Vitals & Biological Age"]
            .firstMatch
        if vitalsCard.waitForExistence(timeout: 5) { vitalsCard.tap() }

        // Tap the Biological Age summary card.
        let bioAgeCard = app.buttons.matching(identifier: "Biological Age").firstMatch
        if bioAgeCard.waitForExistence(timeout: 5) { bioAgeCard.tap() }

        // Either the gauge or the Estimate button should be reachable.
        let estimate = app.buttons["Estimate"]
        XCTAssertTrue(estimate.waitForExistence(timeout: 5),
                      "Biological Age view did not render Estimate button")
    }
}
