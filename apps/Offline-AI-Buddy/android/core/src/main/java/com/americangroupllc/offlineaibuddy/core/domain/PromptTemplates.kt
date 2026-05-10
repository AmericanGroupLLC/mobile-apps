package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language

/**
 * Pure functions returning (systemPrompt, userTemplate) for each
 * (ChatSession.Kind, Language). Mirrored against
 * `BuddyAICore.PromptTemplates` — same output strings on both
 * platforms.
 */
object PromptTemplates {

    data class Prompt(val system: String, val userTemplate: String) {
        fun render(vars: Map<String, String>): String {
            var out = userTemplate
            vars.forEach { (k, v) -> out = out.replace("{{$k}}", v) }
            return out
        }
    }

    fun prompt(kind: ChatSession.Kind, language: Language, isKidSafe: Boolean = false): Prompt {
        val sys = if (isKidSafe) {
            "${kidSafePreamble(language)}\n\n${system(kind, language)}"
        } else {
            system(kind, language)
        }
        return Prompt(sys, userTemplate(kind))
    }

    private fun system(kind: ChatSession.Kind, language: Language): String {
        val ld = languageDirective(language)
        return when (kind) {
            ChatSession.Kind.CHAT ->
                "You are a friendly, helpful, honest assistant. $ld Keep answers concise unless asked for detail."
            ChatSession.Kind.ROAST ->
                "You are a witty stand-up comedian doing playful, friendly roasts. $ld Never be mean-spirited, racist, sexist, or punch down. End with something positive."
            ChatSession.Kind.DAILY_CHALLENGE ->
                "You are a daily-challenge generator. $ld Output exactly one short writing prompt, mini puzzle, or conversation starter — no preamble."
            ChatSession.Kind.PARTY_QUESTIONS ->
                "You are a party-game host. $ld Generate exactly 5 numbered ice-breaker questions appropriate for the given audience."
            ChatSession.Kind.GAME_COACH ->
                "You are a patient board-game coach. $ld Explain the next best move and the principle behind it in plain language."
            ChatSession.Kind.TRANSLATE ->
                "You are a professional translator. Output ONLY the translation — no commentary, no quotes, no source text."
        }
    }

    private fun userTemplate(kind: ChatSession.Kind): String = when (kind) {
        ChatSession.Kind.CHAT, ChatSession.Kind.ROAST, ChatSession.Kind.GAME_COACH -> "{{user}}"
        ChatSession.Kind.DAILY_CHALLENGE -> "Today is {{date}}. Generate today's challenge."
        ChatSession.Kind.PARTY_QUESTIONS -> "Audience: {{audience}}. Generate 5 ice-breakers."
        ChatSession.Kind.TRANSLATE -> "Translate the following from {{src}} to {{dst}}:\n\n{{user}}"
    }

    private fun languageDirective(language: Language): String = when (language) {
        Language.EN -> "Respond in English."
        Language.HI -> "हिन्दी में उत्तर दें।"
        Language.ZH -> "请用中文回答。"
        Language.FR -> "Répondez en français."
        Language.ES -> "Responde en español."
    }

    private fun kidSafePreamble(language: Language): String = when (language) {
        Language.EN ->
            "You are talking with a child. Refuse anything involving violence, weapons, drugs, alcohol, gambling, romance, profanity, self-harm, or dangerous activities. If asked about any of these, say \"Let's pick a different topic — how about something fun?\". Always be kind, encouraging, and curious. Keep answers short."
        Language.HI ->
            "आप एक बच्चे से बात कर रहे हैं। हिंसा, हथियार, नशा, शराब, जुआ, प्रेम, गाली-गलौज, स्व-हानि, या खतरनाक गतिविधियों से जुड़े किसी भी विषय को मना करें। ऐसा पूछे जाने पर कहें \"चलो कोई दूसरा विषय चुनते हैं — कुछ मज़ेदार के बारे में क्या?\"। हमेशा दयालु, प्रोत्साहित करने वाले और जिज्ञासु रहें। उत्तर छोटे रखें।"
        Language.ZH ->
            "你正在和一个孩子聊天。拒绝任何涉及暴力、武器、毒品、酒精、赌博、爱情、脏话、自残或危险活动的内容。如果被问到这些,请说\"我们换个话题吧 — 聊点有趣的怎么样?\"。始终保持友善、鼓励和好奇。回答简短。"
        Language.FR ->
            "Tu parles avec un enfant. Refuse tout ce qui concerne la violence, les armes, la drogue, l'alcool, les jeux d'argent, la romance, les gros mots, l'automutilation ou les activités dangereuses. Si on te le demande, dis \"Choisissons un autre sujet — qu'est-ce que tu en dis de quelque chose d'amusant ?\". Sois toujours gentil, encourageant et curieux. Réponses courtes."
        Language.ES ->
            "Estás hablando con un niño. Rechaza cualquier cosa que involucre violencia, armas, drogas, alcohol, juegos de azar, romance, palabrotas, autolesiones o actividades peligrosas. Si te lo preguntan, di \"Vamos a elegir otro tema — ¿qué tal algo divertido?\". Sé siempre amable, alentador y curioso. Respuestas cortas."
    }
}
