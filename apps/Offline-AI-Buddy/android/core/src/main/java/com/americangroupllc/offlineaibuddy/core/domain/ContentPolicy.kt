package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.Language

/**
 * Per-language regex deny-list. Kid-safe profile truncates the
 * assistant turn from the first match onward and replaces with a
 * kid-friendly redirect. Mirrored against `BuddyAICore.ContentPolicy`.
 */
class ContentPolicy(val language: Language, val isKidSafe: Boolean) {

    data class Result(val filtered: String, val blocked: Boolean)

    fun filter(input: String): Result {
        if (!isKidSafe) return Result(input, false)
        val lower = input.lowercase()
        for (pattern in denylist(language)) {
            val regex = Regex(pattern, RegexOption.IGNORE_CASE)
            val match = regex.find(lower)
            if (match != null) {
                val cut = match.range.first.coerceAtMost(input.length)
                val prefix = input.substring(0, cut)
                return Result(prefix + redirect(language), blocked = true)
            }
        }
        return Result(input, false)
    }

    private fun redirect(lang: Language): String = when (lang) {
        Language.EN -> "Let's pick a different topic — how about something fun?"
        Language.HI -> "चलो कोई दूसरा विषय चुनते हैं — कुछ मज़ेदार के बारे में क्या?"
        Language.ZH -> "我们换个话题吧 — 聊点有趣的怎么样?"
        Language.FR -> "Choisissons un autre sujet — qu'est-ce que tu en dis de quelque chose d'amusant ?"
        Language.ES -> "Vamos a elegir otro tema — ¿qué tal algo divertido?"
    }

    private fun denylist(lang: Language): List<String> = when (lang) {
        Language.EN -> listOf(
            "\\b(kill|murder|attack|weapons?|gun|knife|bomb|blood)\\b",
            "\\b(sex|naked|porn|kiss\\s+me)\\b",
            "\\b(fuck|shit|bitch|asshole|bastard)\\b",
            "\\b(drug|cocaine|heroin|meth|weed|marijuana)\\b",
            "\\b(alcohol|beer|whisky|vodka|drunk)\\b",
            "\\b(gambling|casino|bet|poker)\\b",
            "\\b(suicide|self[-\\s]?harm)\\b",
        )
        Language.HI -> listOf(
            "(मारना|हत्या|हमला|बंदूक|चाकू|बम|खून)",
            "(सेक्स|नंगा|चूमो)",
            "(शराब|बीयर|नशा)",
            "(जुआ|कैसीनो|बाजी)",
            "(आत्महत्या)",
        )
        Language.ZH -> listOf(
            "(杀|谋杀|攻击|武器|枪|刀|炸弹|血)",
            "(性|裸|色情|接吻)",
            "(毒品|可卡因|海洛因)",
            "(酒|啤酒|喝醉)",
            "(赌|赌场|下注)",
            "(自杀|自残)",
        )
        Language.FR -> listOf(
            "\\b(tuer|meurtre|attaquer|arme|pistolet|couteau|bombe|sang)\\b",
            "\\b(sexe|nu|porno|embrasse-moi)\\b",
            "\\b(merde|putain|connard|salope)\\b",
            "\\b(drogue|cocaïne|héroïne|cannabis)\\b",
            "\\b(alcool|bière|whisky|vodka|ivre)\\b",
            "\\b(jeu d'argent|casino|parier|poker)\\b",
            "\\b(suicide|automutilation)\\b",
        )
        Language.ES -> listOf(
            "\\b(matar|asesinato|atacar|arma|pistola|cuchillo|bomba|sangre)\\b",
            "\\b(sexo|desnudo|porno|bésame)\\b",
            "\\b(mierda|joder|cabrón|puta)\\b",
            "\\b(droga|cocaína|heroína|marihuana)\\b",
            "\\b(alcohol|cerveza|whisky|vodka|borracho)\\b",
            "\\b(apuesta|casino|póker)\\b",
            "\\b(suicidio|autolesión)\\b",
        )
    }
}
