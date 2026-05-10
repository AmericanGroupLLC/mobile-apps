package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.WireFrame
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Base64

/**
 * Pure encode/decode for the BuddyPlay wire format. JSON in v1; CBOR opt-in
 * via flag in v1.1.
 */
object WireCodec {

    sealed class Error(message: String) : RuntimeException(message) {
        data class UnsupportedVersion(val v: Int) : Error("unsupported wire version $v")
        data class Malformed(val detail: String) : Error("malformed wire frame: $detail")
    }

    val json: Json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    inline fun <reified P> encode(
        payload: P,
        kind: WireFrame.Kind,
        sessionId: String,
        from: String,
        timestampMillis: Long,
    ): ByteArray {
        val payloadBytes = json.encodeToString(serializer<P>(), payload).toByteArray(Charsets.UTF_8)
        val frame = WireFrame(
            sessionId = sessionId,
            from = from,
            kind = kind,
            ts = timestampMillis,
            payload = Base64.getEncoder().encodeToString(payloadBytes),
        )
        return json.encodeToString(serializer<WireFrame>(), frame).toByteArray(Charsets.UTF_8)
    }

    /** Result of [decode]. */
    data class Decoded<P>(val frame: WireFrame, val payload: P)

    inline fun <reified P> decode(bytes: ByteArray): Decoded<P> {
        val frame = try {
            json.decodeFromString(serializer<WireFrame>(), bytes.toString(Charsets.UTF_8))
        } catch (t: Throwable) {
            throw Error.Malformed("envelope decode failed: ${t.message}")
        }
        if (frame.v != WireFrame.CURRENT_VERSION) {
            throw Error.UnsupportedVersion(frame.v)
        }
        val payloadBytes = try {
            Base64.getDecoder().decode(frame.payload)
        } catch (t: Throwable) {
            throw Error.Malformed("payload base64 decode failed")
        }
        val payload: P = try {
            json.decodeFromString(serializer<P>(), payloadBytes.toString(Charsets.UTF_8))
        } catch (t: Throwable) {
            throw Error.Malformed("payload decode failed: ${t.message}")
        }
        return Decoded(frame, payload)
    }

    /** Length-prefixed framing used by `WifiTcpTransport`. 4-byte big-endian length + bytes. */
    fun frame(bytes: ByteArray): ByteArray {
        val out = ByteArray(4 + bytes.size)
        ByteBuffer.wrap(out, 0, 4).order(ByteOrder.BIG_ENDIAN).putInt(bytes.size)
        System.arraycopy(bytes, 0, out, 4, bytes.size)
        return out
    }

    /**
     * Inverse of [frame]. Returns `null` if the buffer doesn't yet hold a
     * complete frame; the consumer should accumulate more bytes and try
     * again. Returns the parsed payload + the number of bytes consumed.
     */
    fun unframe(buffer: ByteArray): Pair<ByteArray, Int>? {
        if (buffer.size < 4) return null
        val len = ByteBuffer.wrap(buffer, 0, 4).order(ByteOrder.BIG_ENDIAN).int
        val total = 4 + len
        if (buffer.size < total) return null
        val payload = buffer.copyOfRange(4, total)
        return payload to total
    }
}
