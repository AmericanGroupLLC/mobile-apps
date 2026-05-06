import UserNotifications

/// Drift Notification Service Extension. Decrypts message previews and
/// downloads thumbnails so rich pushes show real content instead of
/// "New message".
class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttempt: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttempt = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttempt else { contentHandler(request.content); return }

        // 1. Decrypt previews against the App Group cache.
        if let previewKey = request.content.userInfo["preview_key"] as? String,
           let previewText = decrypt(previewKey: previewKey) {
            bestAttempt.body = previewText
        }

        // 2. Download thumbnail (if any) and attach.
        if let thumbURLString = request.content.userInfo["thumb_url"] as? String,
           let url = URL(string: thumbURLString) {
            URLSession.shared.downloadTask(with: url) { localURL, _, _ in
                if let localURL,
                   let attachment = try? UNNotificationAttachment(
                       identifier: "thumb",
                       url: localURL,
                       options: nil) {
                    bestAttempt.attachments = [attachment]
                }
                contentHandler(bestAttempt)
            }.resume()
        } else {
            contentHandler(bestAttempt)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttempt {
            contentHandler(bestAttempt)
        }
    }

    private func decrypt(previewKey: String) -> String? {
        // App Group SharedDefaults lookup. Production wires up an actual
        // crypto key derived from the user's auth.
        let group = UserDefaults(suiteName: "group.com.americangroupllc.drift")
        return group?.string(forKey: "preview.\(previewKey)")
    }
}
