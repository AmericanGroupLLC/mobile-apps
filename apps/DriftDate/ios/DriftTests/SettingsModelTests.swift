import XCTest
@testable import Drift
import DriftCore

final class SettingsModelTests: XCTestCase {
    @MainActor
    func testTogglingAnalyticsPropagatesToSharedService() {
        let m = SettingsModel.shared
        m.analyticsOptedIn = true
        XCTAssertTrue(AnalyticsService.shared.optedIn)
        m.analyticsOptedIn = false
        XCTAssertFalse(AnalyticsService.shared.optedIn)
    }
}
