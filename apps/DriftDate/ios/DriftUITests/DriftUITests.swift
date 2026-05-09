import XCTest

/// Smoke: launches the app and walks Discover → Wave → Chat. Real flow
/// requires a stubbed Supabase; in CI we just verify the app boots.
final class DriftUITests: XCTestCase {

    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.exists)
    }
}
