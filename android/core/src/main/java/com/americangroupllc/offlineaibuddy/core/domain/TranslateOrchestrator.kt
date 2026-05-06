package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language
import java.net.URLEncoder

/**
 * Pure (srcLang, dstLang, text) -> Prompt for the live translator.
 * Mirrors `BuddyAICore.TranslateOrchestrator`.
 */
object TranslateOrchestrator {

    fun prompt(src: Language, dst: Language, text: String): PromptTemplates.Prompt {
        val base = PromptTemplates.prompt(ChatSession.Kind.TRANSLATE, dst)
        val rendered = base.render(
            mapOf(
                "src" to src.displayName,
                "dst" to dst.displayName,
                "user" to text,
            )
        )
        return PromptTemplates.Prompt(base.system, rendered)
    }

    fun isBetaPair(src: Language, dst: Language): Boolean {
        val s = src to dst
        return s in setOf(
            Language.ZH to Language.HI,
            Language.HI to Language.ZH,
            Language.FR to Language.HI,
            Language.HI to Language.FR,
            Language.ES to Language.HI,
            Language.HI to Language.ES,
        )
    }

    fun googleTranslateUrl(src: Language, dst: Language, text: String): String {
        val encoded = URLEncoder.encode(text, "UTF-8")
        return "https://translate.google.com/?sl=${src.name.lowercase()}&tl=${dst.name.lowercase()}&text=$encoded"
    }
}
