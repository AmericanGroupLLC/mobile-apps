import Foundation

/// Char-frequency + script-range heuristic that returns one of the 5
/// supported v1 languages or `.unknown`. Pure; no model required.
public enum LanguageDetector {

    public enum Detected: Equatable, Sendable {
        case known(Language)
        case unknown
    }

    public static func detect(_ text: String) -> Detected {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .unknown }

        var hi = 0      // Devanagari
        var zh = 0      // CJK Unified Ideographs
        var latin = 0   // Latin block (used for fr/es/en disambiguation)
        var frHints = 0
        var esHints = 0

        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (0x0900...0x097F).contains(v) { hi += 1 }
            else if (0x4E00...0x9FFF).contains(v) || (0x3400...0x4DBF).contains(v) { zh += 1 }
            else if (0x0041...0x024F).contains(v) { latin += 1 }
        }

        if hi > 0 && hi >= zh && hi >= latin / 2 { return .known(.hi) }
        if zh > 0 && zh >= hi && zh >= latin / 2 { return .known(.zh) }

        // Latin-script disambiguation
        let lower = text.lowercased()
        for h in [" le ", " la ", " et ", " est ", " avec ", " bonjour", "ç", "ê", "ô", "œ", "—"] {
            if lower.contains(h) { frHints += 1 }
        }
        for h in [" el ", " la ", " los ", " las ", " hola", " gracias", " ¿", " ¡", "ñ"] {
            if lower.contains(h) { esHints += 1 }
        }

        if frHints > esHints && frHints >= 1 { return .known(.fr) }
        if esHints > frHints && esHints >= 1 { return .known(.es) }
        if latin > 0 { return .known(.en) }
        return .unknown
    }
}
