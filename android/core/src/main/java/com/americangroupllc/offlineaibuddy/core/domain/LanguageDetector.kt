package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.Language

/**
 * Char-frequency + script-range heuristic returning one of 5 known
 * languages or null. Mirrors `BuddyAICore.LanguageDetector`.
 */
object LanguageDetector {

    fun detect(text: String): Language? {
        if (text.isBlank()) return null
        var hi = 0
        var zh = 0
        var latin = 0
        var frHints = 0
        var esHints = 0

        for (c in text) {
            val v = c.code
            when {
                v in 0x0900..0x097F -> hi++
                v in 0x4E00..0x9FFF || v in 0x3400..0x4DBF -> zh++
                v in 0x0041..0x024F -> latin++
            }
        }

        if (hi > 0 && hi >= zh && hi >= latin / 2) return Language.HI
        if (zh > 0 && zh >= hi && zh >= latin / 2) return Language.ZH

        val lower = text.lowercase()
        for (h in listOf(" le ", " la ", " et ", " est ", " avec ", " bonjour", "ç", "ê", "ô", "œ", "—")) {
            if (lower.contains(h)) frHints++
        }
        for (h in listOf(" el ", " la ", " los ", " las ", " hola", " gracias", " ¿", " ¡", "ñ")) {
            if (lower.contains(h)) esHints++
        }

        return when {
            frHints > esHints && frHints >= 1 -> Language.FR
            esHints > frHints && esHints >= 1 -> Language.ES
            latin > 0 -> Language.EN
            else -> null
        }
    }
}
