import Foundation

/// The 5 chat languages v1 ships. Adding a 6th is one new case here +
/// one PromptTemplates entry + one ContentPolicy regex set.
public enum Language: String, Codable, CaseIterable, Sendable {
    case en
    case hi
    case zh
    case fr
    case es

    public var displayName: String {
        switch self {
        case .en: return "English"
        case .hi: return "हिन्दी"
        case .zh: return "中文"
        case .fr: return "Français"
        case .es: return "Español"
        }
    }

    /// Maps to BCP-47 locale identifiers used by AVSpeechSynthesizer +
    /// SFSpeechRecognizer + Android Locale.
    public var localeIdentifier: String {
        switch self {
        case .en: return "en-US"
        case .hi: return "hi-IN"
        case .zh: return "zh-CN"
        case .fr: return "fr-FR"
        case .es: return "es-ES"
        }
    }
}
