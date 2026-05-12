import Foundation

/// Schema-aware structured-extraction interface. Given OCR'd raw text and
/// a list of fields we want to extract, return a `[fieldName: String?]`
/// map. Two implementations:
///
///  • `RegexStructuredExtractor` — ships today, no model download. Each
///    field carries a list of trigger keywords + a value-shape regex.
///    Same pattern as `InsuranceCardOCR.matchAfter(...)`.
///
///  • `OnDeviceLLMStructuredExtractor` — placeholder for week 3+ once a
///    real on-device LLM ships:
///      - iOS 18.1+: Apple Intelligence Foundation Models (Writing
///        Tools / Generation API). A17 Pro / M-series only.
///      - Older iOS: Core ML + a quantized model (Phi-3-mini int4 ~1.5 GB,
///        Gemma 2B int8 ~1.4 GB) loaded via `MLModel`. Out of scope for
///        v1.5.0 because of bundle size.
///      - Android: MediaPipe LLM Inference API runs Gemma 2B on Pixel 6+,
///        Galaxy S23+. Google AI Edge SDK exposes Gemini Nano on Pixel 8 Pro+,
///        S24+.
///
/// Callers use this through `StructuredExtractor.shared`, which today
/// returns the regex impl. A single line at app boot will swap to the
/// LLM impl once a model is bundled — no call-site changes.
public protocol StructuredExtractor: Sendable {
    /// Returns a value (or nil) for each field name in `schema`.
    func extract(text: String, schema: [Field]) async -> [String: String?]
}

public struct Field: Sendable {
    public let name: String
    public let keywords: [String]
    public let valuePattern: String   // RE2/NSRegular-compatible
    public init(name: String, keywords: [String], valuePattern: String) {
        self.name = name
        self.keywords = keywords
        self.valuePattern = valuePattern
    }
}

/// Default impl — pure regex over OCR text. Mirrors the Android
/// `RegexStructuredExtractor` so iOS + Android produce the same fields.
public struct RegexStructuredExtractor: StructuredExtractor {
    public init() {}

    public func extract(text: String, schema: [Field]) async -> [String: String?] {
        var out: [String: String?] = [:]
        for f in schema {
            out[f.name] = matchAfter(keys: f.keywords, pattern: f.valuePattern, in: text)
        }
        return out
    }

    private func matchAfter(keys: [String], pattern: String, in text: String) -> String? {
        for line in text.split(separator: "\n").map(String.init) {
            let lower = line.lowercased()
            guard let key = keys.first(where: { lower.contains($0) }) else { continue }
            let after = line.suffix(line.count - (lower.range(of: key)!.upperBound.utf16Offset(in: lower)))
            if let r = String(after).range(of: pattern, options: .regularExpression) {
                return String(after[r])
            }
        }
        return nil
    }
}

public enum StructuredExtractorRegistry {
    /// Override at app boot to swap to an LLM-backed implementation.
    public static var shared: StructuredExtractor = RegexStructuredExtractor()
}
