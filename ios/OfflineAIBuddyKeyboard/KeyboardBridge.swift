import Foundation

/// Keyboard-extension side of the IPC. Writes a request to the App
/// Group shared file, posts a Darwin notification, listens for the
/// reply notification, then reads the suggestions back. Documented in
/// `KEYBOARD.md` §3.
final class KeyboardBridgeClient {

    static let appGroupId = "group.com.americangroupllc.offlineaibuddy"
    static let requestNotification = "com.americangroupllc.offlineaibuddy.kb.request"
    static let replyNotification = "com.americangroupllc.offlineaibuddy.kb.reply"

    var onReply: (([String]) -> Void)?
    private var pendingRequestId: String?
    private var debounceWorkItem: DispatchWorkItem?

    init() {
        registerForReply()
    }

    func requestSuggestions(forContext context: String) {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.sendRequest(context) }
        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    private func sendRequest(_ context: String) {
        guard let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupId) else { return }
        let req = ["requestId": UUID().uuidString, "context": context]
        pendingRequestId = req["requestId"]
        if let data = try? JSONSerialization.data(withJSONObject: req) {
            try? data.write(to: containerURL.appendingPathComponent("keyboard.request.json"), options: .atomic)
        }
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.requestNotification as CFString),
            nil, nil, true
        )
    }

    private func registerForReply() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let bridge = Unmanaged<KeyboardBridgeClient>.fromOpaque(observer).takeUnretainedValue()
                bridge.handleReply()
            },
            Self.replyNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func handleReply() {
        guard let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupId) else { return }
        let url = containerURL.appendingPathComponent("keyboard.reply.json")
        guard let data = try? Data(contentsOf: url),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let suggestions = dict["suggestions"] as? [String] else { return }
        onReply?(suggestions)
    }
}
