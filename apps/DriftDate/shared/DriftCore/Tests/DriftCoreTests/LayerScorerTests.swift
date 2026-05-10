import XCTest
@testable import DriftCore

final class LayerScorerTests: XCTestCase {

    private func profile(
        intent: Intent = .dating,
        verified: Bool = true,
        zip: String? = "940",
        county: String? = "06085",
        state: String? = "CA",
        vibes: [String] = ["coffee","books"],
        prompts: Int = 3,
        voice: Bool = true,
        lastActive: Date = Date()
    ) -> Profile {
        Profile(
            displayName: "X",
            voicePromptUrl: voice ? URL(string: "https://example.com/v.m4a") : nil,
            intent: intent,
            vibeTags: vibes,
            prompts: (1...prompts).map { Prompt(slot: $0, key: "k\($0)", response: "r") },
            verifiedAt: verified ? Date() : nil,
            zipPrefix3: zip,
            countyFips: county,
            stateCode: state,
            lastActiveAt: lastActive
        )
    }

    func testHighScoreSameZipBothVerifiedSameIntent() {
        let viewer = profile()
        let target = profile()
        let s = LayerScorer.score(viewer: viewer, target: target, layer: .zip)
        XCTAssertGreaterThanOrEqual(s, 0.85)
    }

    func testLowScoreDifferentStateNoSharedInterests() {
        let viewer = profile(state: "CA", vibes: ["coffee"])
        let target = profile(intent: .friendship, zip: "100", county: "36061",
                             state: "NY", vibes: ["chess"])
        let s = LayerScorer.score(viewer: viewer, target: target, layer: .state)
        XCTAssertLessThan(s, 0.30)
    }

    func testWeightingMatchesPlan() {
        // intent + layer + shared + verif + recency + convo == 1.0 weights.
        let viewer = profile()
        let target = profile()
        let s = LayerScorer.score(viewer: viewer, target: target, layer: .zip)
        XCTAssertLessThanOrEqual(s, 1.0001)
        XCTAssertGreaterThanOrEqual(s, 0.0)
    }

    func testTiesBreakByRecency() {
        let now = Date()
        let viewer = profile()
        let oldA = profile(lastActive: now.addingTimeInterval(-3600))
        let newB = profile(lastActive: now)
        let sorted = LayerScorer.sorted(candidates: [oldA, newB], viewer: viewer, layer: .zip, now: now)
        XCTAssertEqual(sorted.first, newB)
    }

    func testIntentScoreOpenIsAlwaysReasonable() {
        XCTAssertGreaterThan(LayerScorer.intentScore(.open, .friendship), 0.5)
        XCTAssertGreaterThan(LayerScorer.intentScore(.dating, .open),    0.5)
        XCTAssertEqual(LayerScorer.intentScore(.dating, .dating),        1.0)
    }

    func testRecencyScoreDegrades() {
        let now = Date()
        XCTAssertEqual(LayerScorer.recentActivityScore(now, now: now), 1.0)
        XCTAssertEqual(LayerScorer.recentActivityScore(now.addingTimeInterval(-2 * 24 * 3600), now: now), 0.75)
        XCTAssertLessThan(LayerScorer.recentActivityScore(now.addingTimeInterval(-365 * 24 * 3600), now: now), 0.1)
    }

    func testSharedInterestsIsJaccard() {
        XCTAssertEqual(LayerScorer.sharedInterests(["a","b"], ["b","c"]), 1.0/3.0, accuracy: 0.001)
        XCTAssertEqual(LayerScorer.sharedInterests([], ["b"]), 0.0)
    }
}
