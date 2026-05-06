import XCTest
@testable import BuddyAICore

final class TranslateOrchestratorTests: XCTestCase {

    func testPromptIncludesSourceAndTarget() {
        let p = TranslateOrchestrator.prompt(src: .en, dst: .hi, text: "Hello, friend.")
        XCTAssertTrue(p.userTemplate.contains("English"))
        XCTAssertTrue(p.userTemplate.contains("हिन्दी"))
        XCTAssertTrue(p.userTemplate.contains("Hello, friend."))
        XCTAssertTrue(p.system.contains("ONLY"))
    }

    func testBetaPairsFlagged() {
        XCTAssertTrue(TranslateOrchestrator.isBetaPair(src: .zh, dst: .hi))
        XCTAssertTrue(TranslateOrchestrator.isBetaPair(src: .hi, dst: .zh))
        XCTAssertFalse(TranslateOrchestrator.isBetaPair(src: .en, dst: .es))
    }

    func testGoogleTranslateFallbackURL() {
        let url = TranslateOrchestrator.googleTranslateURL(src: .en, dst: .hi, text: "hello")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.host, "translate.google.com")
        XCTAssertTrue(url?.absoluteString.contains("sl=en") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("tl=hi") ?? false)
    }

    /// Golden 50-sentence-per-pair regression suite. Slow + needs the
    /// real LLM. Gated behind RUN_TRANSLATION_GOLDEN=1.
    func testGoldenSet() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_TRANSLATION_GOLDEN"] == "1",
                          "set RUN_TRANSLATION_GOLDEN=1 to run the golden translation suite")
        // Real impl would load Tests/Resources/golden-translations.json,
        // run each pair through LlamaRunner, and compare BLEU. v1 ships
        // the gate; the golden file lands when the first model is
        // verified.
    }
}
