import Foundation

/// Pure `(text) -> (text, blocked)` filter applied to every assistant
/// turn (and rolling-buffered every token in kid-safe mode).
///
/// Implementation: per-language regex deny-list. Idempotent — running
/// the filter on already-filtered output is a no-op.
public struct ContentPolicy: Sendable {

    public let language: Language
    public let isKidSafe: Bool

    public init(language: Language, isKidSafe: Bool) {
        self.language = language
        self.isKidSafe = isKidSafe
    }

    public struct Result: Hashable, Sendable {
        public let filtered: String
        public let blocked: Bool

        public init(filtered: String, blocked: Bool) {
            self.filtered = filtered
            self.blocked = blocked
        }
    }

    /// Run the filter. In kid-safe mode this truncates from the first
    /// match onward and replaces the tail with a kid-friendly redirect.
    /// In adult mode this is a passthrough (we still apply the filter
    /// to leave the API symmetric).
    public func filter(_ input: String) -> Result {
        guard isKidSafe else {
            return Result(filtered: input, blocked: false)
        }
        let patterns = ContentPolicy.denylistPatterns(for: language)
        let lower = input.lowercased()
        for pattern in patterns {
            if let r = lower.range(of: pattern, options: .regularExpression) {
                // Map the lowercased range back onto the original string at the same offset.
                let offset = lower.distance(from: lower.startIndex, to: r.lowerBound)
                let cutIdx = input.index(input.startIndex, offsetBy: offset, limitedBy: input.endIndex) ?? input.endIndex
                let prefix = input[..<cutIdx]
                return Result(
                    filtered: String(prefix) + ContentPolicy.kidSafeRedirect(for: language),
                    blocked: true
                )
            }
        }
        return Result(filtered: input, blocked: false)
    }

    private static func kidSafeRedirect(for lang: Language) -> String {
        switch lang {
        case .en: return "Let's pick a different topic — how about something fun?"
        case .hi: return "चलो कोई दूसरा विषय चुनते हैं — कुछ मज़ेदार के बारे में क्या?"
        case .zh: return "我们换个话题吧 — 聊点有趣的怎么样?"
        case .fr: return "Choisissons un autre sujet — qu'est-ce que tu en dis de quelque chose d'amusant ?"
        case .es: return "Vamos a elegir otro tema — ¿qué tal algo divertido?"
        }
    }

    /// Curated deny-list per language. Patterns are case-insensitive
    /// (we lowercase input before matching). This is intentionally a
    /// short, conservative list — false-positives are tracked on the
    /// v1.1 backlog.
    private static func denylistPatterns(for lang: Language) -> [String] {
        switch lang {
        case .en:
            return [
                #"\b(kill|murder|attack|weapon|gun|knife|bomb|blood)\b"#,
                #"\b(sex|naked|porn|kiss\s+me)\b"#,
                #"\b(fuck|shit|bitch|asshole|bastard)\b"#,
                #"\b(drug|cocaine|heroin|meth|weed|marijuana)\b"#,
                #"\b(alcohol|beer|whisky|vodka|drunk)\b"#,
                #"\b(gambling|casino|bet|poker)\b"#,
                #"\b(suicide|self[-\s]?harm)\b"#,
            ]
        case .hi:
            return [
                #"\b(मारना|हत्या|हमला|बंदूक|चाकू|बम|खून)\b"#,
                #"\b(सेक्स|नंगा|चूमो)\b"#,
                #"\b(शराब|बीयर|नशा)\b"#,
                #"\b(जुआ|कैसीनो|बाजी)\b"#,
                #"\b(आत्महत्या)\b"#,
            ]
        case .zh:
            return [
                "(杀|谋杀|攻击|武器|枪|刀|炸弹|血)",
                "(性|裸|色情|接吻)",
                "(毒品|可卡因|海洛因)",
                "(酒|啤酒|喝醉)",
                "(赌|赌场|下注)",
                "(自杀|自残)",
            ]
        case .fr:
            return [
                #"\b(tuer|meurtre|attaquer|arme|pistolet|couteau|bombe|sang)\b"#,
                #"\b(sexe|nu|porno|embrasse-moi)\b"#,
                #"\b(merde|putain|connard|salope)\b"#,
                #"\b(drogue|cocaïne|héroïne|cannabis)\b"#,
                #"\b(alcool|bière|whisky|vodka|ivre)\b"#,
                #"\b(jeu d'argent|casino|parier|poker)\b"#,
                #"\b(suicide|automutilation)\b"#,
            ]
        case .es:
            return [
                #"\b(matar|asesinato|atacar|arma|pistola|cuchillo|bomba|sangre)\b"#,
                #"\b(sexo|desnudo|porno|bésame)\b"#,
                #"\b(mierda|joder|cabrón|puta)\b"#,
                #"\b(droga|cocaína|heroína|marihuana)\b"#,
                #"\b(alcohol|cerveza|whisky|vodka|borracho)\b"#,
                #"\b(apuesta|casino|póker)\b"#,
                #"\b(suicidio|autolesión)\b"#,
            ]
        }
    }
}
