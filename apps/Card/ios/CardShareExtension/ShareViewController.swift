import UIKit
import Social
import UniformTypeIdentifiers
import CardCore

/// Receives shared text, writes a Card to the App Group's CardStore, dismisses.
/// The main app is never launched.
class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || hasAttachedText()
    }

    override func didSelectPost() {
        let prefilled = contentText ?? ""
        loadAttachedText { [weak self] attached in
            let combined = [prefilled, attached]
                .compactMap { $0 }
                .joined(separator: prefilled.isEmpty || (attached ?? "").isEmpty ? "" : "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            self?.save(text: combined)
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! { [] }

    private func hasAttachedText() -> Bool {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return false }
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                    || provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    return true
                }
            }
        }
        return false
    }

    private func loadAttachedText(_ completion: @escaping (String?) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(nil); return
        }
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { obj, _ in
                        DispatchQueue.main.async { completion(obj as? String) }
                    }
                    return
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { obj, _ in
                        DispatchQueue.main.async {
                            if let url = obj as? URL { completion(url.absoluteString) }
                            else { completion(nil) }
                        }
                    }
                    return
                }
            }
        }
        completion(nil)
    }

    private func save(text: String) {
        guard !text.isEmpty, let store = CardStore.appGroup() else { return }
        var current = store.load()
        current.append(Card(text: text, kind: .note))
        do {
            try store.save(current)
            AnalyticsService.shared.track(.cardCaptured(surface: .shareExtension, kind: .note))
        } catch {
            CrashReportingService.shared.capture(error)
        }
    }
}
