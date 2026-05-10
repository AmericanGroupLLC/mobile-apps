package com.americangroupllc.offlineaibuddy.core.storage

import com.google.common.truth.Truth.assertThat
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class ModelStoreKtTest {

    @get:Rule val tmp = TemporaryFolder()

    @Test
    fun install_and_remove() {
        val store = ModelStore(tmp.root)
        val src = File(tmp.root, "dl.bin").apply { writeText("hello") }
        val installed = store.install(src, "model.gguf")
        assertThat(installed.exists()).isTrue()
        assertThat(store.isInstalled("model.gguf")).isTrue()
        store.remove("model.gguf")
        assertThat(store.isInstalled("model.gguf")).isFalse()
    }

    @Test
    fun verify_empty_sha_skips() {
        val store = ModelStore(tmp.root)
        val src = File(tmp.root, "dl.bin").apply { writeText("anything") }
        store.install(src, "model.gguf")
        assertThat(store.verify("model.gguf", expectedSha256 = "")).isTrue()
    }

    @Test
    fun verify_mismatch_fails() {
        val store = ModelStore(tmp.root)
        val src = File(tmp.root, "dl.bin").apply { writeText("hello") }
        store.install(src, "model.gguf")
        assertThat(store.verify("model.gguf", expectedSha256 = "deadbeef")).isFalse()
    }
}
