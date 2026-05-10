import Foundation

/// Pure `(srcLang, dstLang, text) -> Prompt` for the live translator
/// feature. Built on top of `PromptTemplates` but tested separately
/// because of the golden-set regression suite.
public enum TranslateOrchestrator {

    /// Build the LLM prompt for a translation request.
    public static func prompt(src: Language, dst: Language, text: String) -> PromptTemplates.Prompt {
        let base = PromptTemplates.prompt(kind: .translate, language: dst)
        let rendered = base.render([
            "src": src.displayName,
            "dst": dst.displayName,
            "user": text,
        ])
        return PromptTemplates.Prompt(system: base.system, userTemplate: rendered)
    }

    /// Whether a translation pair has known low quality (surfaces a
    /// "Beta translation" banner + Google Translate deep-link in UI).
    public static func isBetaPair(src: Language, dst: Language) -> Bool {
        // Lower-resource pairs identified in MODELS.md §5.
        switch (src, dst) {
        case (.zh, .hi), (.hi, .zh),
             (.fr, .hi), (.hi, .fr),
             (.es, .hi), (.hi, .es):
            return true
        default:
            return false
        }
    }

    /// Build a `https://translate.google.com/?sl=...&tl=...&text=...` URL
    /// the UI offers as a comfort-fallback for beta pairs. We never embed
    /// any SDK; this is just an outbound deep-link.
    public static func googleTranslateURL(src: Language, dst: Language, text: String) -> URL? {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        return URL(string: "https://translate.google.com/?sl=\(src.rawValue)&tl=\(dst.rawValue)&text=\(encoded)")
    }
}
