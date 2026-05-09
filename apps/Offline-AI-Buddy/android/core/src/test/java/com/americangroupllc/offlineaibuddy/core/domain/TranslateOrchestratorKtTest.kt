package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.Language
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class TranslateOrchestratorKtTest {

    @Test
    fun prompt_includes_source_and_target() {
        val p = TranslateOrchestrator.prompt(Language.EN, Language.HI, "Hello, friend.")
        assertThat(p.userTemplate).contains("English")
        assertThat(p.userTemplate).contains("हिन्दी")
        assertThat(p.userTemplate).contains("Hello, friend.")
        assertThat(p.system).contains("ONLY")
    }

    @Test
    fun beta_pairs_flagged() {
        assertThat(TranslateOrchestrator.isBetaPair(Language.ZH, Language.HI)).isTrue()
        assertThat(TranslateOrchestrator.isBetaPair(Language.HI, Language.ZH)).isTrue()
        assertThat(TranslateOrchestrator.isBetaPair(Language.EN, Language.ES)).isFalse()
    }

    @Test
    fun google_translate_url_constructed() {
        val url = TranslateOrchestrator.googleTranslateUrl(Language.EN, Language.HI, "hello")
        assertThat(url).contains("translate.google.com")
        assertThat(url).contains("sl=en")
        assertThat(url).contains("tl=hi")
    }
}
