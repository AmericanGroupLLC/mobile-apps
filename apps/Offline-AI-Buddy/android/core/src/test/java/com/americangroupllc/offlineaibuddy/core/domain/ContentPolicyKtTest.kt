package com.americangroupllc.offlineaibuddy.core.domain

import com.americangroupllc.offlineaibuddy.core.models.Language
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ContentPolicyKtTest {

    @Test
    fun adult_passes_everything_through() {
        val r = ContentPolicy(Language.EN, isKidSafe = false).filter("kill the bug")
        assertThat(r.blocked).isFalse()
    }

    @Test
    fun kid_safe_blocks_violent_english() {
        val r = ContentPolicy(Language.EN, isKidSafe = true).filter("Let's kill people")
        assertThat(r.blocked).isTrue()
        assertThat(r.filtered).contains("different topic")
    }

    @Test
    fun kid_safe_blocks_hindi_violence() {
        val r = ContentPolicy(Language.HI, isKidSafe = true).filter("उसे मारना नहीं चाहिए।")
        assertThat(r.blocked).isTrue()
    }

    @Test
    fun kid_safe_blocks_mandarin_violence() {
        val r = ContentPolicy(Language.ZH, isKidSafe = true).filter("不要杀人。")
        assertThat(r.blocked).isTrue()
    }

    @Test
    fun kid_safe_blocks_french_profanity() {
        val r = ContentPolicy(Language.FR, isKidSafe = true).filter("c'est de la merde")
        assertThat(r.blocked).isTrue()
    }

    @Test
    fun kid_safe_blocks_spanish_alcohol() {
        val r = ContentPolicy(Language.ES, isKidSafe = true).filter("Tomemos cerveza juntos")
        assertThat(r.blocked).isTrue()
    }

    @Test
    fun idempotent_on_already_filtered() {
        val policy = ContentPolicy(Language.EN, isKidSafe = true)
        val r1 = policy.filter("Let's discuss weapons.")
        assertThat(r1.blocked).isTrue()
        val r2 = policy.filter(r1.filtered)
        assertThat(r2.blocked).isFalse()
    }
}
