import Foundation

/// Pure functions returning `(systemPrompt, userPrompt)` for each
/// `(ChatSession.Kind, Language)`. Tested via golden snapshot to make
/// sure prompt drift is caught in CI.
public enum PromptTemplates {

    public struct Prompt: Hashable, Sendable {
        public let system: String
        public let userTemplate: String     // may contain `{{user}}`, `{{src}}`, `{{dst}}` etc.

        public init(system: String, userTemplate: String) {
            self.system = system
            self.userTemplate = userTemplate
        }

        /// Substitute `{{key}}` placeholders.
        public func render(_ vars: [String: String]) -> String {
            var out = userTemplate
            for (k, v) in vars {
                out = out.replacingOccurrences(of: "{{\(k)}}", with: v)
            }
            return out
        }
    }

    /// Returns the prompt for a given `(kind, language, isKidSafe)` triple.
    /// Kid-safe variants override the system prompt with the strict
    /// refusal preamble in the target language.
    public static func prompt(
        kind: ChatSession.Kind,
        language: Language,
        isKidSafe: Bool = false
    ) -> Prompt {
        if isKidSafe {
            return Prompt(
                system: kidSafePreamble(for: language) + "\n\n" + system(for: kind, language: language),
                userTemplate: userTemplate(for: kind)
            )
        }
        return Prompt(
            system: system(for: kind, language: language),
            userTemplate: userTemplate(for: kind)
        )
    }

    // MARK: - System prompts

    private static func system(for kind: ChatSession.Kind, language: Language) -> String {
        let langDirective = languageDirective(for: language)
        switch kind {
        case .chat:
            return "You are a friendly, helpful, honest assistant. \(langDirective) Keep answers concise unless asked for detail."
        case .roast:
            return "You are a witty stand-up comedian doing playful, friendly roasts. \(langDirective) Never be mean-spirited, racist, sexist, or punch down. End with something positive."
        case .dailyChallenge:
            return "You are a daily-challenge generator. \(langDirective) Output exactly one short writing prompt, mini puzzle, or conversation starter — no preamble."
        case .partyQuestions:
            return "You are a party-game host. \(langDirective) Generate exactly 5 numbered ice-breaker questions appropriate for the given audience."
        case .gameCoach:
            return "You are a patient board-game coach. \(langDirective) Explain the next best move and the principle behind it in plain language."
        case .translate:
            return "You are a professional translator. Output ONLY the translation — no commentary, no quotes, no source text."
        }
    }

    private static func userTemplate(for kind: ChatSession.Kind) -> String {
        switch kind {
        case .chat, .roast, .gameCoach:
            return "{{user}}"
        case .dailyChallenge:
            return "Today is {{date}}. Generate today's challenge."
        case .partyQuestions:
            return "Audience: {{audience}}. Generate 5 ice-breakers."
        case .translate:
            return "Translate the following from {{src}} to {{dst}}:\n\n{{user}}"
        }
    }

    private static func languageDirective(for lang: Language) -> String {
        switch lang {
        case .en: return "Respond in English."
        case .hi: return "हिन्दी में उत्तर दें।"
        case .zh: return "请用中文回答。"
        case .fr: return "Répondez en français."
        case .es: return "Responde en español."
        }
    }

    private static func kidSafePreamble(for lang: Language) -> String {
        switch lang {
        case .en:
            return "You are talking with a child. Refuse anything involving violence, weapons, drugs, alcohol, gambling, romance, profanity, self-harm, or dangerous activities. If asked about any of these, say \"Let's pick a different topic — how about something fun?\". Always be kind, encouraging, and curious. Keep answers short."
        case .hi:
            return "आप एक बच्चे से बात कर रहे हैं। हिंसा, हथियार, नशा, शराब, जुआ, प्रेम, गाली-गलौज, स्व-हानि, या खतरनाक गतिविधियों से जुड़े किसी भी विषय को मना करें। ऐसा पूछे जाने पर कहें \"चलो कोई दूसरा विषय चुनते हैं — कुछ मज़ेदार के बारे में क्या?\"। हमेशा दयालु, प्रोत्साहित करने वाले और जिज्ञासु रहें। उत्तर छोटे रखें।"
        case .zh:
            return "你正在和一个孩子聊天。拒绝任何涉及暴力、武器、毒品、酒精、赌博、爱情、脏话、自残或危险活动的内容。如果被问到这些,请说\"我们换个话题吧 — 聊点有趣的怎么样?\"。始终保持友善、鼓励和好奇。回答简短。"
        case .fr:
            return "Tu parles avec un enfant. Refuse tout ce qui concerne la violence, les armes, la drogue, l'alcool, les jeux d'argent, la romance, les gros mots, l'automutilation ou les activités dangereuses. Si on te le demande, dis \"Choisissons un autre sujet — qu'est-ce que tu en dis de quelque chose d'amusant ?\". Sois toujours gentil, encourageant et curieux. Réponses courtes."
        case .es:
            return "Estás hablando con un niño. Rechaza cualquier cosa que involucre violencia, armas, drogas, alcohol, juegos de azar, romance, palabrotas, autolesiones o actividades peligrosas. Si te lo preguntan, di \"Vamos a elegir otro tema — ¿qué tal algo divertido?\". Sé siempre amable, alentador y curioso. Respuestas cortas."
        }
    }
}
