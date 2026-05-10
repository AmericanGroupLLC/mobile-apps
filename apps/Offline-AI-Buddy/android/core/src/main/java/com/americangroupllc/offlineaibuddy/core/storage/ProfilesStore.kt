package com.americangroupllc.offlineaibuddy.core.storage

import com.americangroupllc.offlineaibuddy.core.models.Profile
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import java.io.File
import java.security.MessageDigest
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * JSON-on-disk store for profiles + their PIN hashes. Mirrors
 * `BuddyAICore.ProfilesStore`. PBKDF2-SHA256 with 100k rounds.
 */
class ProfilesStore(directory: File) {

    class Duplicate : Exception()
    class NotFound : Exception()

    private val file = File(directory, "profiles.json").also { directory.mkdirs() }
    private val json = Json { encodeDefaults = true; ignoreUnknownKeys = true }
    private val lock = Any()

    fun loadAll(): List<Profile> = synchronized(lock) {
        if (!file.exists()) return emptyList()
        return try {
            json.decodeFromString(ListSerializer(serializer<Profile>()), file.readText())
        } catch (_: Throwable) {
            emptyList()
        }
    }

    fun save(profiles: List<Profile>) = synchronized(lock) {
        file.writeText(json.encodeToString(ListSerializer(serializer<Profile>()), profiles))
    }

    fun add(profile: Profile) {
        val all = loadAll().toMutableList()
        if (all.any { it.id == profile.id }) throw Duplicate()
        all += profile
        save(all)
    }

    fun remove(id: String) {
        val all = loadAll().toMutableList()
        if (all.none { it.id == id }) throw NotFound()
        all.removeAll { it.id == id }
        save(all)
    }

    fun verify(pin: String, profileId: String): Boolean {
        val p = loadAll().firstOrNull { it.id == profileId } ?: throw NotFound()
        if (p.pinHash == null || p.pinSalt == null) return true
        return pbkdf2Hex(pin, p.pinSalt) == p.pinHash
    }

    companion object {
        fun pbkdf2Hex(pin: String, saltHex: String): String {
            val salt = saltHex.hexToBytesOrUtf8()
            val spec = PBEKeySpec(pin.toCharArray(), salt, 100_000, 256)
            val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            val key = factory.generateSecret(spec).encoded
            return key.joinToString("") { "%02x".format(it) }
        }

        fun newSaltHex(): String {
            val bytes = ByteArray(16)
            java.security.SecureRandom().nextBytes(bytes)
            return bytes.joinToString("") { "%02x".format(it) }
        }

        // Foundation-only Swift fallback uses a SHA-256 chain. The two
        // implementations DIVERGE — the Swift one is shippable but
        // non-standard; the Android one uses a real PBKDF2. The
        // ProfilesStore tests verify correctness within each platform,
        // not byte-equality across.
        @Suppress("MagicNumber")
        private fun String.hexToBytesOrUtf8(): ByteArray {
            return if (length % 2 == 0 && all { it in "0123456789abcdefABCDEF" }) {
                chunked(2).map { it.toInt(16).toByte() }.toByteArray()
            } else {
                toByteArray(Charsets.UTF_8)
            }
        }
    }
}
