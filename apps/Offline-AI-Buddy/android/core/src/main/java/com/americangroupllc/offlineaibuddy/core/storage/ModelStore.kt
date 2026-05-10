package com.americangroupllc.offlineaibuddy.core.storage

import java.io.File
import java.security.MessageDigest

/**
 * On-disk layout for the GGUF model file. Mirrors `BuddyAICore.ModelStore`.
 */
class ModelStore(directory: File) {

    val directory: File = File(directory, "models").also { it.mkdirs() }

    fun urlFor(name: String): File = File(directory, name)

    fun isInstalled(name: String): Boolean = urlFor(name).exists()

    /** Move a downloaded file into the store. Atomic replace. */
    fun install(downloaded: File, name: String): File {
        val dest = urlFor(name)
        if (dest.exists()) dest.delete()
        if (!downloaded.renameTo(dest)) {
            downloaded.copyTo(dest, overwrite = true)
            downloaded.delete()
        }
        return dest
    }

    fun remove(name: String) {
        val target = urlFor(name)
        if (target.exists()) target.delete()
    }

    /** SHA-256 hex digest of an installed model. `expectedSha256 = ""` skips. */
    fun verify(name: String, expectedSha256: String): Boolean {
        if (expectedSha256.isEmpty()) return true
        val target = urlFor(name)
        if (!target.exists()) return false
        val digest = MessageDigest.getInstance("SHA-256")
        target.inputStream().use { input ->
            val buf = ByteArray(1024 * 1024)
            while (true) {
                val read = input.read(buf)
                if (read <= 0) break
                digest.update(buf, 0, read)
            }
        }
        val actual = digest.digest().joinToString("") { "%02x".format(it) }
        return actual.equals(expectedSha256, ignoreCase = true)
    }
}
