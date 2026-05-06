package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.Language
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class LanguageDetectorKtTest {

    @Test fun english() = assertThat(LanguageDetector.detect("Hello how are you doing today?")).isEqualTo(Language.EN)
    @Test fun hindi() = assertThat(LanguageDetector.detect("नमस्ते, आप कैसे हैं?")).isEqualTo(Language.HI)
    @Test fun mandarin() = assertThat(LanguageDetector.detect("你好,你今天怎么样?")).isEqualTo(Language.ZH)
    @Test fun french() = assertThat(LanguageDetector.detect("Bonjour, comment ça va aujourd'hui?")).isEqualTo(Language.FR)
    @Test fun spanish() = assertThat(LanguageDetector.detect("Hola, ¿cómo estás hoy?")).isEqualTo(Language.ES)

    @Test fun blank_returns_null() {
        assertThat(LanguageDetector.detect("   ")).isNull()
        assertThat(LanguageDetector.detect("")).isNull()
    }

    @Test fun mixed_returns_dominant() {
        assertThat(LanguageDetector.detect("नमस्ते hi कैसे हैं?")).isEqualTo(Language.HI)
    }

    @Test fun numeric_fallback_returns_english() {
        assertThat(LanguageDetector.detect("abc 123")).isEqualTo(Language.EN)
    }
}
