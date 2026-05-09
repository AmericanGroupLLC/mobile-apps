package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.WireFrame
import com.google.common.truth.Truth.assertThat
import kotlinx.serialization.Serializable
import org.junit.Test
import java.util.UUID

class WireCodecKtTest {

    @Serializable
    data class Probe(val a: Int, val b: String)

    @Test
    fun roundTrip() {
        val sessionId = UUID.randomUUID().toString()
        val from = UUID.randomUUID().toString()
        val payload = Probe(42, "hello")
        val bytes = WireCodec.encode(payload, WireFrame.Kind.INPUT, sessionId, from, 1735689600000L)
        val decoded = WireCodec.decode<Probe>(bytes)
        assertThat(decoded.frame.v).isEqualTo(WireFrame.CURRENT_VERSION)
        assertThat(decoded.frame.sessionId).isEqualTo(sessionId)
        assertThat(decoded.frame.from).isEqualTo(from)
        assertThat(decoded.frame.kind).isEqualTo(WireFrame.Kind.INPUT)
        assertThat(decoded.frame.ts).isEqualTo(1735689600000L)
        assertThat(decoded.payload).isEqualTo(payload)
    }

    @Test(expected = WireCodec.Error.UnsupportedVersion::class)
    fun rejectsUnknownVersion() {
        val envelopeJson = """
            {"v":999,"sessionId":"x","from":"y","kind":"INPUT","ts":0,"payload":""}
        """.trimIndent()
        WireCodec.decode<Probe>(envelopeJson.toByteArray(Charsets.UTF_8))
    }

    @Test
    fun frameUnframeRoundTripsLengthPrefixed() {
        val payload = byteArrayOf(1,2,3,4,5,6,7)
        val framed = WireCodec.frame(payload)
        assertThat(framed.size).isEqualTo(4 + payload.size)
        val (out, consumed) = WireCodec.unframe(framed)!!
        assertThat(out).isEqualTo(payload)
        assertThat(consumed).isEqualTo(framed.size)
    }

    @Test
    fun unframeReturnsNullOnPartialBuffer() {
        val payload = byteArrayOf(1,2,3,4,5,6,7)
        val framed = WireCodec.frame(payload)
        assertThat(WireCodec.unframe(framed.copyOfRange(0, 3))).isNull()
        assertThat(WireCodec.unframe(framed.copyOfRange(0, framed.size - 1))).isNull()
    }
}
