package com.myhealth.app.vision

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class InsuranceCardOcrTest {

    private val ocr = InsuranceCardOcr()

    @Test
    fun `extracts canonical fields from a typical card layout`() {
        val sample = """
            BlueCross BlueShield
            Member ID: ABC1234567
            Group #: GRP998877
            Rx BIN: 610014
            PCN: ABCDE
            RxGrp: 12345
        """.trimIndent()
        val r = ocr.extract(sample)
        assertThat(r.payer).isEqualTo("BlueCross BlueShield")
        assertThat(r.memberId).isEqualTo("ABC1234567")
        assertThat(r.groupNumber).isEqualTo("GRP998877")
        assertThat(r.bin).isEqualTo("610014")
        assertThat(r.pcn).isEqualTo("ABCDE")
        assertThat(r.rxGrp).isEqualTo("12345")
    }

    @Test
    fun `gracefully handles a card with only member id`() {
        val sample = "Aetna\nMember ID: XYZ9999"
        val r = ocr.extract(sample)
        assertThat(r.payer).isEqualTo("Aetna")
        assertThat(r.memberId).isEqualTo("XYZ9999")
        assertThat(r.groupNumber).isNull()
        assertThat(r.bin).isNull()
    }

    @Test
    fun `is case-insensitive for keys`() {
        val sample = "AETNA\nmember id: lower123"
        val r = ocr.extract(sample)
        assertThat(r.memberId).isEqualTo("lower123")
    }
}
