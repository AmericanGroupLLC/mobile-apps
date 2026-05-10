package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class PromptTemplatesKtTest {

    @Test
    fun every_kind_and_language_produces_non_empty() {
        for (kind in ChatSession.Kind.values()) {
            for (lang in Language.values()) {
                val p = PromptTemplates.prompt(kind, lang)
                assertThat(p.system).isNotEmpty()
                assertThat(p.userTemplate).isNotEmpty()
            }
        }
    }

    @Test
    fun kid_safe_preamble_is_prepended() {
        val p = PromptTemplates.prompt(ChatSession.Kind.CHAT, Language.EN, isKidSafe = true)
        assertThat(p.system).contains("child")
    }

    @Test
    fun kid_safe_preamble_hindi() {
        val p = PromptTemplates.prompt(ChatSession.Kind.CHAT, Language.HI, isKidSafe = true)
        assertThat(p.system).contains("बच्चे")
    }

    @Test
    fun translate_system_prompt_forbids_commentary() {
        val p = PromptTemplates.prompt(ChatSession.Kind.TRANSLATE, Language.EN)
        assertThat(p.system).contains("ONLY")
        assertThat(p.system.lowercase()).contains("commentary")
    }

    @Test
    fun render_substitutes_placeholders() {
        val p = PromptTemplates.prompt(ChatSession.Kind.CHAT, Language.EN)
        assertThat(p.render(mapOf("user" to "Hello"))).isEqualTo("Hello")
    }

    @Test
    fun golden_snapshot_sample_english_chat() {
        val p = PromptTemplates.prompt(ChatSession.Kind.CHAT, Language.EN)
        assertThat(p.system)
            .isEqualTo("You are a friendly, helpful, honest assistant. Respond in English. Keep answers concise unless asked for detail.")
    }
}
