package com.americangroupllc.offlineaibuddy.core.models

import kotlinx.serialization.Serializable

@Serializable
data class ModelManifest(
    val name: String,
    val version: Int,
    val urls: List<String>,
    val sizeBytes: Long,
    val sha256: String,
    val contextSize: Int,
    val minDeviceRAM: Long,
) {
    companion object {
        val defaultV1 = ModelManifest(
            name = "Qwen2.5-1.5B-Instruct-Q4_K_M",
            version = 1,
            urls = listOf(
                "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
                "https://huggingface.co/lmstudio-community/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf",
            ),
            sizeBytes = 1_073_741_824L,
            sha256 = "",          // set in MODELS.md when first build verified
            contextSize = 4096,
            minDeviceRAM = 3_500_000_000L,
        )
    }
}
