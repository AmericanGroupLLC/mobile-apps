import XCTest
@testable import BuddyAICore

final class LanguageDetectorTests: XCTestCase {

    func testEnglish() {
        XCTAssertEqual(LanguageDetector.detect("Hello how are you doing today?"), .known(.en))
    }

    func testHindi() {
        XCTAssertEqual(LanguageDetector.detect("नमस्ते, आप कैसे हैं?"), .known(.hi))
    }

    func testMandarin() {
        XCTAssertEqual(LanguageDetector.detect("你好,你今天怎么样?"), .known(.zh))
    }

    func testFrench() {
        XCTAssertEqual(LanguageDetector.detect("Bonjour, comment ça va aujourd'hui?"), .known(.fr))
    }

    func testSpanish() {
        XCTAssertEqual(LanguageDetector.detect("Hola, ¿cómo estás hoy?"), .known(.es))
    }

    func testEmptyReturnsUnknown() {
        XCTAssertEqual(LanguageDetector.detect("    "), .unknown)
        XCTAssertEqual(LanguageDetector.detect(""), .unknown)
    }

    func testMixedReturnsDominant() {
        // Mostly Devanagari with a couple of latin words → Hindi.
        XCTAssertEqual(LanguageDetector.detect("नमस्ते hi कैसे हैं?"), .known(.hi))
    }

    func testNumericFallback() {
        // Pure digits + ASCII punctuation default to .en if there's any latin char.
        XCTAssertEqual(LanguageDetector.detect("abc 123"), .known(.en))
    }
}
