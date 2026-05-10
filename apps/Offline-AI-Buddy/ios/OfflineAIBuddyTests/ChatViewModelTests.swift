import XCTest
@testable import OfflineAIBuddy
import BuddyAICore

final class ChatViewModelTests: XCTestCase {

    @MainActor
    func testConsumeStreamAppendsAssistantMessageOnFinish() async {
        let vm = ChatViewModel()
        let stream = AsyncStream<Token> { continuation in
            continuation.yield(Token(text: "Hello "))
            continuation.yield(Token(text: "world", isLast: true))
            continuation.finish()
        }
        await vm.consume(stream, isKidSafe: false, language: .en)
        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.messages.first?.text, "Hello world")
    }

    @MainActor
    func testConsumeStopsOnContentPolicyBlockWhenKidSafe() async {
        let vm = ChatViewModel()
        let stream = AsyncStream<Token> { continuation in
            continuation.yield(Token(text: "We could "))
            continuation.yield(Token(text: "kill them all", isLast: true))
            continuation.finish()
        }
        await vm.consume(stream, isKidSafe: true, language: .en)
        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertTrue(vm.messages.first?.text.contains("different topic") ?? false)
    }
}
