package com.americangroupllc.offlineaibuddy.llm

/**
 * Kotlin-side declarations for the JNI llama.cpp bindings. The real
 * implementations live in `src/main/cpp/llama_jni.cpp`; the stub
 * variant in `llama_jni_stub.cpp` is built when the submodule is
 * absent so the linker is happy in CI.
 */
class LlamaJni {
    private external fun loadModelNative(path: String, contextSize: Int): Long
    private external fun unloadModelNative(handle: Long)
    private external fun generateNative(handle: Long, systemPrompt: String, userPrompt: String, maxTokens: Int): String

    private var handle: Long = 0L

    fun load(path: String, contextSize: Int): Boolean {
        handle = loadModelNative(path, contextSize)
        // 0 = stub mode (or load failure). The caller reads `isLoaded`.
        return true
    }

    fun unload() {
        if (handle != 0L) {
            unloadModelNative(handle)
            handle = 0L
        }
    }

    val isLoaded: Boolean get() = handle != 0L

    fun generate(systemPrompt: String, userPrompt: String, maxTokens: Int = 512): String {
        return generateNative(handle, systemPrompt, userPrompt, maxTokens)
    }

    companion object {
        init {
            try {
                System.loadLibrary("offline_ai_buddy")
            } catch (_: Throwable) {
                // No native library on host JVM (unit tests). LlamaService
                // detects this and uses the stub generator.
            }
        }
    }
}
