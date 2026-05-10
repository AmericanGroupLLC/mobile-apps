import XCTest
@testable import BuddyAICore

final class PromptTemplatesTests: XCTestCase {

    func testEveryKindAndLanguageProducesNonEmpty() {
        for kind in ChatSession.Kind.allCases {
            for lang in Language.allCases {
                let p = PromptTemplates.prompt(kind: kind, language: lang)
                XCTAssertFalse(p.system.isEmpty, "system empty for \(kind) \(lang)")
                XCTAssertFalse(p.userTemplate.isEmpty, "userTemplate empty for \(kind) \(lang)")
            }
        }
    }

    func testKidSafePreambleIsPrepended() {
        let p = PromptTemplates.prompt(kind: .chat, language: .en, isKidSafe: true)
        XCTAssertTrue(p.system.contains("child"))
    }

    func testKidSafePreambleHindi() {
        let p = PromptTemplates.prompt(kind: .chat, language: .hi, isKidSafe: true)
        XCTAssertTrue(p.system.contains("बच्चे"))
    }

    func testTranslateSystemPromptForbidsCommentary() {
        let p = PromptTemplates.prompt(kind: .translate, language: .en)
        XCTAssertTrue(p.system.contains("ONLY"))
        XCTAssertTrue(p.system.lowercased().contains("commentary"))
    }

    func testRenderSubstitutesPlaceholders() {
        let p = PromptTemplates.prompt(kind: .chat, language: .en)
        let rendered = p.render(["user": "Hello"])
        XCTAssertEqual(rendered, "Hello")
    }

    func testGoldenSnapshotSampleEnglishChat() {
        // Stable golden — change required if PromptTemplates intentionally moves.
        let p = PromptTemplates.prompt(kind: .chat, language: .en)
        XCTAssertEqual(
            p.system,
            "You are a friendly, helpful, honest assistant. Respond in English. Keep answers concise unless asked for detail."
        )
    }
}
